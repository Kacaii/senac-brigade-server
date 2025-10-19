import app/database
import app/routes/admin/sql
import app/routes/role
import app/routes/user
import app/web.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import gleam/string
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
) {
  use <- wisp.require_method(req, http.Put)
  use body <- wisp.require_json(req)

  case decode.run(body, body_decoder()) {
    Error(err) -> handle_decode_error(err)
    Ok(value) -> handle_body(req, ctx, value, user_id)
  }
}

fn handle_body(
  req: wisp.Request,
  ctx: Context,
  body: AdminUpdateUserBody,
  user_id: String,
) -> wisp.Response {
  case try_update_user(req, ctx, body, user_id) {
    Ok(data) -> wisp.json_response(json.to_string(data), 200)
    Error(err) -> handle_error(req, body, err)
  }
}

fn handle_error(
  req: wisp.Request,
  body: AdminUpdateUserBody,
  err: AdminUpdateUserError,
) -> wisp.Response {
  case err {
    DataBaseError(err) -> {
      case err {
        pog.ConstraintViolated(_, _, constraint:) -> {
          case constraint {
            // Unique Email
            "user_account_email_key" ->
              wisp.bad_request("Email já está sendo utilizado: " <> body.email)
            // Unique Registration
            "user_account_registration_key" ->
              wisp.bad_request(
                "Matrícula já está sendo utilizada: " <> body.registration,
              )

            _ -> database.handle_database_error(err)
          }
        }
        err -> database.handle_database_error(err)
      }
    }
    InvalidUuid(err) ->
      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text("Usuário possui Uuid inválido: " <> err))
    UuidNotFound(id) -> wisp.bad_request("Usuário não encontrado: " <> id)
    RoleError(err) -> user.handle_authorization_error(req, err)
  }
}

fn try_update_user(
  req: wisp.Request,
  ctx: Context,
  body: AdminUpdateUserBody,
  user_id: String,
) {
  use _ <- result.try(
    user.check_role_authorization(
      request: req,
      ctx:,
      cookie_name: "USER_ID",
      authorized_roles: [role.Admin, role.Developer],
    )
    |> result.map_error(RoleError),
  )

  use user_uuid <- result.try(
    uuid.from_string(user_id)
    |> result.replace_error(InvalidUuid(user_id)),
  )

  use returned <- result.try(
    sql.admin_update_user(
      ctx.conn,
      user_uuid,
      body.full_name,
      body.email,
      role_to_enum(body.user_role),
      body.registration,
      body.is_active,
    )
    |> result.map_error(DataBaseError),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(UuidNotFound(user_id)),
  )

  let user_role = enum_to_role(row.user_role)

  json.object([
    #("id", json.string(uuid.to_string(row.id))),
    #("full_name", json.string(row.full_name)),
    #("email", json.nullable(row.email, json.string)),
    #("user_role", json.string(role.to_string_pt_br(user_role))),
    #("registration", json.string(row.registration)),
    #("updated_at", json.float(row.updated_at |> timestamp.to_unix_seconds())),
    #("is_active", json.bool(row.is_active)),
  ])
}

fn enum_to_role(enum: sql.UserRoleEnum) {
  case enum {
    sql.Admin -> role.Admin
    sql.Analist -> role.Analist
    sql.Captain -> role.Captain
    sql.Developer -> role.Developer
    sql.Firefighter -> role.Firefighter
    sql.Sargeant -> role.Sargeant
  }
}

fn role_to_enum(role: role.Role) {
  case role {
    role.Admin -> sql.Admin
    role.Analist -> sql.Analist
    role.Captain -> sql.Captain
    role.Developer -> sql.Developer
    role.Firefighter -> sql.Firefighter
    role.Sargeant -> sql.Sargeant
  }
}

fn handle_decode_error(err: List(decode.DecodeError)) -> wisp.Response {
  case err {
    [] -> wisp.ok()
    [err, ..] -> {
      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text(
        "Esperava: "
        <> err.expected
        <> "\nEncontrado: "
        <> err.found
        <> "\nEm: "
        <> string.join(err.path, "/"),
      ))
    }
  }
}

fn body_decoder() {
  use full_name <- decode.field("full_name", decode.string)
  use email <- decode.field("email", decode.string)
  use user_role <- decode.field("user_role", role.decoder())
  use registration <- decode.field("registration", decode.string)
  use is_active <- decode.field("is_active", decode.bool)

  decode.success(AdminUpdateUserBody(
    full_name:,
    email:,
    user_role:,
    registration:,
    is_active:,
  ))
}

type AdminUpdateUserBody {
  AdminUpdateUserBody(
    full_name: String,
    email: String,
    user_role: role.Role,
    registration: String,
    is_active: Bool,
  )
}

type AdminUpdateUserError {
  DataBaseError(pog.QueryError)
  InvalidUuid(String)
  RoleError(user.AuthorizationError)
  UuidNotFound(String)
}
