import app/database
import app/routes/role
import app/routes/user
import app/routes/user/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

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

fn handle_error(req: wisp.Request, err: DeleteUserError) -> wisp.Response {
  case err {
    InvalidUserUuid(invalid_uuid) ->
      wisp.bad_request("Usuário possui Uuid Inválido: " <> invalid_uuid)
    UuidNotFound(id) -> wisp.bad_request("Usuário não encontrado: " <> id)
    RoleError(err) -> user.handle_authorization_error(req, err)
    DataBaseError(err) -> database.handle_database_error(err)
  }
}

fn try_delete_user(
  req: wisp.Request,
  ctx: Context,
  id: String,
) -> Result(String, DeleteUserError) {
  use target_user_uuid <- result.try(
    uuid.from_string(id)
    |> result.replace_error(InvalidUserUuid(id)),
  )

  use _ <- result.try(
    user.check_role_authorization(
      request: req,
      ctx:,
      cookie_name: "USER_ID",
      authorized_roles: [role.Admin, role.Developer],
    )
    |> result.map_error(RoleError),
  )

  use returned <- result.try(
    sql.delete_user_by_id(ctx.conn, target_user_uuid)
    |> result.map_error(DataBaseError),
  )

  case list.first(returned.rows) {
    Error(_) -> Error(UuidNotFound(id))
    Ok(row) -> {
      json.object([
        #("id", json.string(uuid.to_string(row.id))),
        #("full_name", json.string(row.full_name)),
      ])
      |> json.to_string
      |> Ok
    }
  }
}

type DeleteUserError {
  DataBaseError(pog.QueryError)
  InvalidUserUuid(String)
  RoleError(user.AuthorizationError)
  UuidNotFound(String)
}
