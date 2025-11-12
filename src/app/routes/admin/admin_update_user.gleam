import app/routes/admin/sql
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
import pog
import wisp
import youid/uuid

/// 󰚰  Update an user information with admin privileges and
/// return the update data as formatted JSON
///
/// ## Response
///
/// ```json
/// {
///   "id": "550e8400-e29b-41d4-a716-446655440000",
///   "full_name": "João Silva",
///   "email": "joao.silva@example.com",
///   "user_role": "administrador",
///   "registration": "20230001",
///   "updated_at": 1698765432.123,
///   "is_active": true
/// }
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id user_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Put)
  use body <- wisp.require_json(req)

  case decode.run(body, body_decoder()) {
    Error(err) -> web.handle_decode_error(err)
    Ok(value) -> handle_body(req, ctx, value, user_id)
  }
}

fn handle_body(
  req: wisp.Request,
  ctx: Context,
  body: RequestBody,
  user_id: String,
) -> wisp.Response {
  case try_update_user(req, ctx, body, user_id) {
    Ok(body) -> wisp.json_response(body, 200)
    Error(err) -> handle_error(req, body, err)
  }
}

type AdminUpdateUserError {
  /// Failed to access the DataBase
  DataBaseError(pog.QueryError)
  /// User has invalid Uuid format
  InvalidUuid(String)
  /// Authentication / Authorization failed
  AccessError(user.AccessControlError)
  /// User not found in the DataBase
  UserNotFound(uuid.Uuid)
}

fn handle_error(
  req: wisp.Request,
  body: RequestBody,
  err: AdminUpdateUserError,
) -> wisp.Response {
  case err {
    AccessError(err) -> user.handle_access_control_error(req, err)

    InvalidUuid(id) -> wisp.bad_request("Usuário possui Uuid inválido: " <> id)

    UserNotFound(id) ->
      wisp.Text("Usuário não encontrado: " <> uuid.to_string(id))
      |> wisp.set_body(wisp.not_found(), _)

    DataBaseError(err) -> {
      case err {
        pog.ConstraintViolated(_, _, constraint: "user_account_email_key") ->
          wisp.Text("Email já está sendo utilizado: " <> body.email)
          |> wisp.set_body(wisp.response(409), _)

        pog.ConstraintViolated(
          _,
          _,
          constraint: "user_account_registration_key",
        ) -> {
          wisp.Text("Matrícula já está sendo utilizada: " <> body.registration)
          |> wisp.set_body(wisp.response(409), _)
        }

        err -> web.handle_database_error(err)
      }
    }
  }
}

fn try_update_user(
  req: wisp.Request,
  ctx: Context,
  body: RequestBody,
  user_id: String,
) -> Result(String, AdminUpdateUserError) {
  use _ <- result.try(
    user.check_role_authorization(
      request: req,
      ctx:,
      cookie_name: user.uuid_cookie_name,
      authorized_roles: [role.Admin, role.Developer],
    )
    |> result.map_error(AccessError),
  )

  use user_uuid <- result.try(
    uuid.from_string(user_id)
    |> result.replace_error(InvalidUuid(user_id)),
  )

  use returned <- result.try(
    sql.admin_update_user(
      ctx.db,
      user_uuid,
      body.full_name,
      body.email,
      role_to_enum(body.user_role),
      body.registration,
      body.is_active,
    )
    |> result.map_error(DataBaseError),
  )

  case list.first(returned.rows) {
    Error(_) -> Error(UserNotFound(user_uuid))
    Ok(row) -> {
      let user_role = case row.user_role {
        sql.Admin -> role.Admin
        sql.Analyst -> role.Analyst
        sql.Captain -> role.Captain
        sql.Developer -> role.Developer
        sql.Firefighter -> role.Firefighter
        sql.Sargeant -> role.Sargeant
      }

      let updated_at_json =
        json.float(
          row.updated_at
          |> timestamp.to_unix_seconds(),
        )

      json.object([
        #("id", json.string(uuid.to_string(row.id))),
        #("full_name", json.string(row.full_name)),
        #("email", json.string(row.email)),
        #("user_role", json.string(role.to_string_pt_br(user_role))),
        #("registration", json.string(row.registration)),
        #("updated_at", updated_at_json),
        #("is_active", json.bool(row.is_active)),
      ])
      |> json.to_string
      |> Ok
    }
  }
}

fn role_to_enum(role: role.Role) {
  case role {
    role.Admin -> sql.Admin
    role.Analyst -> sql.Analyst
    role.Captain -> sql.Captain
    role.Developer -> sql.Developer
    role.Firefighter -> sql.Firefighter
    role.Sargeant -> sql.Sargeant
  }
}

fn body_decoder() {
  use full_name <- decode.field("full_name", decode.string)
  use email <- decode.field("email", decode.string)
  use user_role <- decode.field("user_role", role.decoder())
  use registration <- decode.field("registration", decode.string)
  use is_active <- decode.field("is_active", decode.bool)

  decode.success(RequestBody(
    full_name:,
    email:,
    user_role:,
    registration:,
    is_active:,
  ))
}

type RequestBody {
  RequestBody(
    full_name: String,
    email: String,
    user_role: role.Role,
    registration: String,
    is_active: Bool,
  )
}
