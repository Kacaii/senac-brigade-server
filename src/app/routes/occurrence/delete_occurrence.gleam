
import app/routes/occurrence/sql
import app/routes/user
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

///   Deleting an occurrence can fail
type DeleteOccurrenceError {
  /// 󰿀  Occurrence has invalid Uuid
  InvalidUuid(String)
  ///   Authentication failed
  AuthenticationError(user.AuthenticationError)
  /// 󱙀  Failed to query the DataBase
  DataBaseError(pog.QueryError)
  /// 󱪘  Occurrence was not found in the system 
  OccurrenceNotFound(uuid.Uuid)
}

/// 󱪟  Remove a occurrence from the Database and returns its uuid
/// as a JSON formatted response
///
/// ## Response
///
/// ```json
/// {
///   "id": "fc025473-a83d-426e-b423-2d79c26d4362"
/// }
///
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id occurrence_id_str: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)

  case try_delete_occurrence(req, ctx, occurrence_id_str) {
    Ok(deleted_id) -> wisp.json_response(deleted_id, 200)
    Error(err) -> handle_error(err)
  }
}

fn try_delete_occurrence(
  req: wisp.Request,
  ctx: Context,
  id_str: String,
) -> Result(String, DeleteOccurrenceError) {
  use occ_uuid <- result.try(
    uuid.from_string(id_str)
    |> result.replace_error(InvalidUuid(id_str)),
  )

  use _user_uuid <- result.try(
    // Armazenamos o UUID do usuário caso precisemos para autorização
    user.auth_user_from_cookie(request: req, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AuthenticationError),
  )

  use returned <- result.try(
    sql.delete_occurrence_by_id(ctx.conn, occ_uuid)
    |> result.map_error(DataBaseError),
  )

  case list.first(returned.rows) {
    Error(_) -> Error(OccurrenceNotFound(occ_uuid))
    Ok(row) -> {
      json.object([#("id", json.string(uuid.to_string(row.id)))])
      |> json.to_string()
      |> Ok
    }
  }
}

fn handle_error(err: DeleteOccurrenceError) -> wisp.Response {
  case err {
    InvalidUuid(uuid_string) ->
      // 404 Bad Request
      wisp.bad_request("UUID inválido: " <> uuid_string)
    AuthenticationError(auth_err) -> user.handle_authentication_error(auth_err)
    DataBaseError(db_err) -> web.handle_database_error(db_err)
    OccurrenceNotFound(occ_uuid) -> {
      // 404 not found
      let resp = wisp.not_found()
      // Response body
      wisp.Text("Ocorrência não encontrada: " <> uuid.to_string(occ_uuid))
      |> wisp.set_body(resp, _)
    }
  }
}
