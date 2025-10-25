import app/database
import app/routes/role
import app/routes/user/sql
import app/web.{type Context}
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

pub const uuid_cookie_name = "USER_ID"

///   Errors related to user access control (authentication & authorization)
pub type AccessControlError {
  /// 󰗹  Authentication failed
  Authentication(AuthenticationError)
  ///   User is authentication but lacks permissions
  Authorization(
    user_uuid: uuid.Uuid,
    user_role: role.Role,
    authorized_roles: List(role.Role),
  )
  /// 󰆼  DataBase operation failed during access control check
  DataBase(pog.QueryError)
  /// 󰡦  User role was not found in system
  RoleNotFound
  ///   User doesnt have a valid role
  InvalidRole(String)
}

///   Authentication-specific failures
pub type AuthenticationError {
  ///   Request is missing the authetication Cookie
  MissingCookie
  /// 󰘨  User doesn't have a valid UUID
  InvalidUUID(String)
}

///   Query the database to find the user's role name
pub fn get_user_role(
  ctx ctx: Context,
  user_uuid id: uuid.Uuid,
) -> Result(role.Role, AccessControlError) {
  use returned <- result.try(
    sql.query_user_role(ctx.conn, id)
    |> result.map_error(DataBase),
  )

  case list.first(returned.rows) {
    Error(_) -> Error(RoleNotFound)
    Ok(row) ->
      Ok(case row.user_role {
        sql.Admin -> role.Admin
        sql.Analist -> role.Analist
        sql.Captain -> role.Captain
        sql.Developer -> role.Developer
        sql.Firefighter -> role.Firefighter
        sql.Sargeant -> role.Sargeant
      })
  }
}

///   Extracts the user UUID from the request's Cookie
pub fn auth_user_from_cookie(
  request request: wisp.Request,
  cookie_name cookie_name: String,
) -> Result(uuid.Uuid, AuthenticationError) {
  use maybe_uuid <- result.try(
    wisp.get_cookie(request:, name: cookie_name, security: wisp.Signed)
    |> result.replace_error(MissingCookie),
  )

  use user_uuid <- result.try(
    uuid.from_string(maybe_uuid)
    |> result.replace_error(InvalidUUID(maybe_uuid)),
  )

  Ok(user_uuid)
}

/// 󰡦  Extracts the user UUID from the request and query the DataBase
/// to verify if the user has authorization to access determined endpoint
pub fn check_role_authorization(
  request request: wisp.Request,
  ctx ctx: Context,
  cookie_name cookie_name: String,
  authorized_roles authorized_roles: List(role.Role),
) -> Result(#(uuid.Uuid, role.Role), AccessControlError) {
  //   Indentify who is sending the request -----------------------------------
  use user_uuid <- result.try(
    auth_user_from_cookie(request:, cookie_name:)
    |> result.map_error(Authentication),
  )

  // 󰯦  Query the User's role --------------------------------------------------
  use user_role <- result.try(get_user_role(ctx, user_uuid))

  // 󰈞  Check if that role has authorization -----------------------------------
  use user_role <- result.try(
    list.find(authorized_roles, fn(authorized) { user_role == authorized })
    |> result.replace_error(Authorization(
      user_uuid:,
      user_role:,
      authorized_roles:,
    )),
  )

  Ok(#(user_uuid, user_role))
}

pub fn handle_authentication_error(err: AuthenticationError) {
  case err {
    InvalidUUID(id) ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text("ID de usuário inválido: " <> id))
    MissingCookie ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text("Cookie de autenticação ausente"))
  }
}

pub fn handle_access_control_error(req: wisp.Request, err: AccessControlError) {
  case err {
    Authentication(auth_err) -> handle_authentication_error(auth_err)
    DataBase(db_err) -> database.handle_database_error(db_err)
    RoleNotFound -> {
      // 401 Unauthorized
      let resp = wisp.response(401)
      // Body
      let body =
        wisp.Text("Não foi possível confirmar o Cargo do usuário autenticado")

      // 󱃜  Send response
      wisp.set_body(resp, body)
    }

    InvalidRole(role_string) ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text(
        "Usuário autenticado possui cargo inválido: " <> role_string,
      ))

    Authorization(user_uuid:, user_role:, authorized_roles:) -> {
      //   LOG
      role.log_unauthorized_access_attempt(
        request: req,
        user_uuid:,
        user_role:,
        required: authorized_roles,
      )

      // JSON BODY
      let role_to_json = fn(role: role.Role) {
        role.to_string_pt_br(role) |> json.string
      }

      // Response
      let resp = wisp.response(403)
      let body =
        json.object([
          #("id", json.string(uuid.to_string(user_uuid))),
          #("user_role", json.string(role.to_string_pt_br(user_role:))),
          #("required", json.array(authorized_roles, role_to_json)),
        ])
        |> json.to_string

      wisp.json_response(body, resp.status)
    }
  }
}
