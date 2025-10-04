import app/routes/role
import app/routes/user/sql
import app/web.{type Context}
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

pub fn get_role_name(
  ctx ctx: Context,
  user_uuid id: uuid.Uuid,
) -> Result(String, UserAccountError) {
  use returned <- result.try(
    sql.query_user_role_name(ctx.conn, id)
    |> result.map_error(DataBaseError),
  )
  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(DataBaseReturnedEmptyRow),
  )

  Ok(row.role_name)
}

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

pub type AuthenticationError {
  MissingCookie
  InvalidUUID(String)
}

/// 󰡦  Extracts the user UUID from the request and query the DataBase
/// to verify if the user has authorization to access determined endpoint
///
pub fn check_role_authorization(
  request request: wisp.Request,
  ctx ctx: Context,
  cookie_name cookie_name: String,
  authorized_roles authorized_roles: List(role.Role),
) -> Result(role.Role, UserAccountError) {
  //   Indentify who is sending the request -----------------------------------
  use user_uuid <- result.try(
    auth_user_from_cookie(request:, cookie_name:)
    |> result.map_error(AuthenticationFailed),
  )
  // 󰯦  Query the User's role name ---------------------------------------------
  use role_name <- result.try(get_role_name(ctx, user_uuid))
  let role = role.from_string(role_name:)

  // 󰈞  Check if that role has authorization -----------------------------------
  use found <- result.try(
    list.find(authorized_roles, fn(x) { x == role })
    |> result.replace_error(Unauthorized(user_uuid, role)),
  )

  Ok(found)
}

///   Errors related to an User account or role
pub type UserAccountError {
  ///   User is not authorized to access data
  Unauthorized(uuid.Uuid, role.Role)
  /// 󰗹  Failed to authenticate user
  AuthenticationFailed(AuthenticationError)
  /// 󰆼  DataBase query failed
  DataBaseError(pog.QueryError)
  /// 󰡦  DataBase found no results
  DataBaseReturnedEmptyRow
}
