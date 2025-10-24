import app/database
import app/routes/role
import app/routes/user/sql
import app/web.{type Context}
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

pub const uuid_cookie_name = "USER_ID"

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
    Ok(row) -> Ok(enum_to_role(row.user_role))
  }
}

fn enum_to_role(user_role: sql.UserRoleEnum) -> role.Role {
  case user_role {
    sql.Admin -> role.Admin
    sql.Analist -> role.Analist
    sql.Captain -> role.Captain
    sql.Developer -> role.Developer
    sql.Firefighter -> role.Firefighter
    sql.Sargeant -> role.Sargeant
  }
}

///   Extracts the user UUID from the request's Cookie
pub fn auth_user_from_cookie(
  request request: wisp.Request,
  cookie_name cookie_name: String,
) -> Result(uuid.Uuid, AuthenticationError) {
  use user_id <- result.try(
    wisp.get_cookie(request:, name: cookie_name, security: wisp.Signed)
    |> result.replace_error(MissingCookie),
  )

  use user_uuid <- result.try(
    uuid.from_string(user_id)
    |> result.replace_error(InvalidUUID(user_id)),
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
    |> result.replace_error(Authorization(user_uuid, user_role)),
  )

  Ok(#(user_uuid, user_role))
}

///   Errors related to user access control (authentication & authorization)
pub type AccessControlError {
  /// 󰗹  Authentication failed
  Authentication(AuthenticationError)
  ///   User is authentication but lacks permissions
  Authorization(uuid.Uuid, role.Role)
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

pub fn handle_authorization_error(req: wisp.Request, err: AccessControlError) {
  case err {
    Authentication(err) -> handle_authentication_error(err)
    DataBase(err) -> database.handle_database_error(err)
    RoleNotFound ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text(
        "Não foi possível confirmar o Cargo do usuário autenticado",
      ))
    InvalidRole(err) ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text(
        "Usuário autenticado possui cargo inválido: " <> err,
      ))
    Authorization(user_uuid, user_role) -> {
      role.log_unauthorized_access_attempt(req, user_uuid:, user_role:)
      wisp.response(403)
      |> wisp.set_body(wisp.Text(
        "Não autorizado: " <> role.to_string_pt_br(user_role:),
      ))
    }
  }
}
