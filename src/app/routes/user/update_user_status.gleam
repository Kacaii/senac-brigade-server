import app/database
import app/routes/role
import app/routes/user
import app/routes/user/sql
import app/web.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

/// 󰚰  Update an user `is_active` field and return the updated data
/// as formatted JSON response
///
/// ## Response
///
/// ```json
/// {
///   "id": "c3d4e5f6-g7h8-9012-cdef-345678901234",
///   "is_active": true
/// }
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id user_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Put)
  use json_data <- wisp.require_json(req)

  case decode.run(json_data, body_decoder()) {
    Error(err) -> web.handle_decode_error(err)
    Ok(is_active) -> {
      case try_update_user_status(req:, ctx:, user_id:, is_active:) {
        Error(err) -> handle_error(req, err)
        Ok(resp) -> wisp.json_response(resp, 200)
      }
    }
  }
}

fn try_update_user_status(
  req req: wisp.Request,
  ctx ctx: Context,
  user_id user_id: String,
  is_active is_active: Bool,
) -> Result(String, UpdateUserStatusError) {
  use _ <- result.try(
    user.check_role_authorization(
      request: req,
      ctx: ctx,
      cookie_name: user.uuid_cookie_name,
      authorized_roles: [role.Admin, role.Developer],
    )
    |> result.map_error(RoleError),
  )

  use user_uuid <- result.try(
    uuid.from_string(user_id)
    |> result.replace_error(InvalidUuid(user_id)),
  )

  use returned <- result.try(
    sql.update_user_status(ctx.conn, user_uuid, is_active)
    |> result.map_error(DataBaseError),
  )

  case list.first(returned.rows) {
    Error(_) -> Error(UserNotFound(user_id))
    Ok(row) ->
      json.object([
        #("id", json.string(uuid.to_string(row.id))),
        #("is_active", json.bool(row.is_active)),
      ])
      |> json.to_string
      |> Ok
  }
}

fn handle_error(req: wisp.Request, err: UpdateUserStatusError) -> wisp.Response {
  case err {
    InvalidUuid(user_id) ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text("Usuário possui UUID inválido: " <> user_id))
    UserNotFound(id) -> wisp.bad_request("Usuário não encontrado: " <> id)
    RoleError(err) -> user.handle_authorization_error(req, err)
    DataBaseError(err) -> database.handle_database_error(err)
  }
}

fn body_decoder() -> decode.Decoder(Bool) {
  use is_active <- decode.field("status", decode.bool)
  decode.success(is_active)
}

type UpdateUserStatusError {
  RoleError(user.AuthorizationError)
  UserNotFound(String)
  InvalidUuid(String)
  DataBaseError(pog.QueryError)
}
