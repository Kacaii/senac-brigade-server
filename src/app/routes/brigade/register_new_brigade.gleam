import app/routes/brigade
import app/routes/brigade/sql
import app/routes/role
import app/routes/user
import app/web
import app/web/context.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import gleam/time/timestamp
import group_registry
import pog
import wisp
import youid/uuid

///   Insert a new brigade into the database.
/// Performs validation on all the members UUID
/// and return relevant data as formatted JSON response.
///
/// ## Response
///
/// ```json
/// {
///   "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
///   "created_at": 1759790156.0
///   "members": [
///     "99acee85-3c8c-4ad6-9c91-2bda49b1b833",
///     "89d95896-eafd-4701-9e13-20adcb56c81e",
///     "7de2d080-a7fa-4307-a824-b696c09d08da"
///   ]
/// }
/// ```
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Post)
  use body <- wisp.require_json(request)

  case decode.run(body, body_decoder()) {
    Ok(body) -> handle_body(request:, ctx:, body:)
    Error(err) -> web.handle_decode_error(err)
  }
}

/// Body sent by the Client in during the request
type RequestBody {
  RequestBody(
    /// Id of the brigade leader
    leader_id: uuid.Uuid,
    /// Name of the brigade
    name: String,
    /// Code of the brigade's vehicle
    vehicle_code: String,
    /// All members meant to be assigned to the brigade
    members_id: List(uuid.Uuid),
    /// Brigade status
    is_active: Bool,
  )
}

/// Registering a new brigade can fail
type RegisterBrigadeError {
  /// Uuid contain invalid format
  InvalidUuid(String)
  /// An error occurred while accessing the Database
  DataBase(pog.QueryError)
  /// Brigade not found in the Database
  BrigadeNotFound
  /// Error related to Authentication / Authorization
  AccessError(user.AccessControlError)
}

fn body_decoder() {
  let uuid_decoder = {
    use maybe_uuid <- decode.then(decode.string)
    case uuid.from_string(maybe_uuid) {
      Error(_) -> decode.failure(uuid.v7(), "uuid")
      Ok(value) -> decode.success(value)
    }
  }

  let members_decoder = {
    use members <- decode.then(decode.list(of: uuid_decoder))
    decode.success(members)
  }

  use leader_id <- decode.field("liderId", uuid_decoder)
  use name <- decode.field("nome", decode.string)
  use vehicle_code <- decode.field("codigoViatura", decode.string)
  use is_active <- decode.field("ativo", decode.bool)
  use members_id <- decode.field("membros", members_decoder)

  decode.success(RequestBody(
    leader_id:,
    name:,
    vehicle_code:,
    members_id:,
    is_active:,
  ))
}

fn handle_body(
  request request: wisp.Request,
  ctx ctx: Context,
  body body: RequestBody,
) -> wisp.Response {
  case try_register_brigade(request:, ctx:, body:) {
    Ok(body) -> wisp.json_response(body, 201)
    Error(err) -> handle_error(request:, err:)
  }
}

fn try_register_brigade(
  request request: wisp.Request,
  ctx ctx: Context,
  body body: RequestBody,
) -> Result(String, RegisterBrigadeError) {
  use _ <- result.try(
    user.check_role_authorization(
      request:,
      ctx:,
      cookie_name: user.uuid_cookie_name,
      authorized_roles: [role.Admin, role.Developer],
    )
    |> result.map_error(AccessError),
  )

  use returned <- result.try(
    sql.insert_new_brigade(
      ctx.db,
      body.leader_id,
      body.name,
      body.vehicle_code,
      body.is_active,
    )
    |> result.map_error(DataBase),
  )

  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(BrigadeNotFound),
  )

  use assigned_members <- result.map(try_assign_members(
    ctx:,
    to: row.id,
    assign: body.members_id,
  ))

  let members_json =
    json.array(assigned_members, fn(member) {
      uuid.to_string(member) |> json.string
    })

  json.to_string(
    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("created_at", json.float(timestamp.to_unix_seconds(row.created_at))),
      #("members", members_json),
    ]),
  )
}

fn try_assign_members(
  ctx ctx: Context,
  assign members: List(uuid.Uuid),
  to brigade_id: uuid.Uuid,
) -> Result(List(uuid.Uuid), RegisterBrigadeError) {
  use returned <- result.map(
    sql.assign_brigade_members(ctx.db, brigade_id, members)
    |> result.map_error(DataBase),
  )

  let assigned_members = {
    use row <- list.map(returned.rows)
    row.inserted_user_id
  }

  //   BROADCAST --------------------------------------------------------------
  let registry = group_registry.get_registry(ctx.registry_name)
  brigade.broadcast_assignments(assigned_members:, to: brigade_id, registry:)

  assigned_members
}

fn handle_error(request request, err err: RegisterBrigadeError) -> wisp.Response {
  case err {
    InvalidUuid(user_id) ->
      wisp.bad_request("Usuário possui UUID inválido: " <> user_id)
    DataBase(err) -> web.handle_database_error(err)
    AccessError(err) -> user.handle_access_control_error(request, err)
    BrigadeNotFound ->
      "O Banco de Dados não retornou informações sobre a nova equipe após a inserção"
      |> wisp.Text
      |> wisp.set_body(wisp.not_found(), _)
  }
}
