import app/domain/role
import app/domain/user
import app/domain/user/sql
import app/web
import app/web/context.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

/// 󰀕  Remove an user account from the database and
/// return their uuid as a formatted JSON response.
///
/// ```json
/// {
///   "id": "92ce4d0b-59e2-4437-bbf1-ebad7b59a9f1"
/// }
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id user_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)

  case try_delete_user(req, ctx, user_id) {
    Ok(deleted_user) -> wisp.json_response(deleted_user, 200)
    Error(err) -> handle_error(req, err)
  }
}

///   Deleting an user can fail
type DeleteUserError {
  /// 󱙀  An error occurred while accessing the DataBase
  DataBase(pog.QueryError)
  /// 󰘨  Target user has invalid Uuid
  InvalidUserUuid(String)
  /// 󱋟  Errors related to authentication and authorization
  AccessControl(user.AccessControlError)
  /// 󰀒  User was not found in the Database
  UserNotFound(uuid.Uuid)
  /// 󱅞  An user should not be able to delete theirself
  CantDeleteSelf
}

fn handle_error(req: wisp.Request, err: DeleteUserError) -> wisp.Response {
  case err {
    InvalidUserUuid(invalid_uuid) ->
      wisp.bad_request("Usuário possui Uuid Inválido: " <> invalid_uuid)
    UserNotFound(user_uuid) ->
      wisp.bad_request("Usuário não encontrado: " <> uuid.to_string(user_uuid))
    AccessControl(err) -> user.handle_access_control_error(req, err)
    DataBase(err) -> web.handle_database_error(err)
    CantDeleteSelf -> wisp.bad_request("Um usuário não deve remover a si mesmo")
  }
}

fn try_delete_user(
  req: wisp.Request,
  ctx: Context,
  target_id: String,
) -> Result(String, DeleteUserError) {
  use target_user_uuid <- result.try(
    uuid.from_string(target_id)
    |> result.replace_error(InvalidUserUuid(target_id)),
  )

  use #(user_uuid, _) <- result.try(
    user.check_role_authorization(
      request: req,
      ctx:,
      cookie_name: user.uuid_cookie_name,
      authorized_roles: [role.Admin, role.Developer],
    )
    |> result.map_error(AccessControl),
  )

  case uuid.to_string(user_uuid) == target_id {
    True -> Error(CantDeleteSelf)
    False -> {
      use returned <- result.try(
        sql.delete_user_by_id(ctx.db, target_user_uuid)
        |> result.map_error(DataBase),
      )

      use row <- result.map(
        list.first(returned.rows)
        |> result.replace_error(UserNotFound(user_uuid)),
      )

      [
        #("id", json.string(uuid.to_string(row.id))),
        #("full_name", json.string(row.full_name)),
      ]
      |> json.object
      |> json.to_string
    }
  }
}
