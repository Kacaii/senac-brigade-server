import app/routes/role
import app/routes/user/sql
import app/web.{type Context}
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

///   Query the database to find the user's role name
pub fn get_user_role(
  ctx ctx: Context,
  user_uuid id: uuid.Uuid,
) -> Result(role.Role, AuthorizationError) {
  use returned <- result.try(
    sql.query_user_role(ctx.conn, id)
    |> result.map_error(DataBaseError),
  )
  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(FailedToQueryUserRole),
  )

  let user_role =
    row.user_role
    |> enum_to_role()

  Ok(user_role)
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
) -> Result(role.Role, AuthorizationError) {
  //   Indentify who is sending the request -----------------------------------
  use user_uuid <- result.try(
    auth_user_from_cookie(request:, cookie_name:)
    |> result.map_error(AuthenticationFailed),
  )
  // 󰯦  Query the User's role --------------------------------------------------
  use user_role <- result.try(get_user_role(ctx, user_uuid))

  // 󰈞  Check if that role has authorization -----------------------------------
  use found <- result.try(
    list.find(authorized_roles, fn(authorized) { user_role == authorized })
    |> result.replace_error(Unauthorized(user_uuid, user_role)),
  )

  Ok(found)
}

///   Errors related to an User account or role
pub type AuthorizationError {
  ///   User is not authorized to access data
  Unauthorized(uuid.Uuid, role.Role)
  /// 󰗹  Failed to authenticate user
  AuthenticationFailed(AuthenticationError)
  /// 󰆼  DataBase query failed
  DataBaseError(pog.QueryError)
  /// 󰡦  DataBase found no results
  FailedToQueryUserRole
  ///   User doesnt have a valid role
  InvalidRole(String)
}

///   Authentication can fail
pub type AuthenticationError {
  ///   Request is missing the authetication Cookie
  MissingCookie
  /// 󰘨  User doesnt have a valid UUID
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
