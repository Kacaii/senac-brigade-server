import app/database
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

type DeleteOccurrenceError {
  InvalidUuid(String)
  AuthenticationError(user.AuthenticationError)
  DataBaseError(pog.QueryError)
  OccurrenceNotFound(String)
}

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
    Ok(deleted_id) ->
      wisp.ok()
      |> wisp.set_body(wisp.Text(
        json.object([#("id", json.string(uuid.to_string(deleted_id)))])
        |> json.to_string(),
      ))
    Error(err) -> handle_error(req, err)
  }
}

fn try_delete_occurrence(
  req: wisp.Request,
  ctx: Context,
  id_str: String,
) -> Result(uuid.Uuid, DeleteOccurrenceError) {
  use occurrence_uuid <- result.try(
    uuid.from_string(id_str)
    |> result.replace_error(InvalidUuid(id_str)),
  )

  use _user_uuid <- result.try(
    // Armazenamos o UUID do usuário caso precisemos para autorização
    user.auth_user_from_cookie(request: req, cookie_name: "USER_ID")
    |> result.map_error(AuthenticationError),
  )

  use returned <- result.try(
    sql.delete_occurrence_by_id(ctx.conn, occurrence_uuid)
    |> result.map_error(DataBaseError),
  )

  case list.first(returned.rows) {
    Ok(row) -> Ok(row.id)
    Error(_) -> Error(OccurrenceNotFound(id_str))
  }
}

fn handle_error(_req: wisp.Request, err: DeleteOccurrenceError) -> wisp.Response {
  case err {
    InvalidUuid(id) -> wisp.bad_request("ID de ocorrência inválido: " <> id)
    AuthenticationError(auth_err) -> user.handle_authentication_error(auth_err)
    DataBaseError(db_err) -> database.handle_database_error(db_err)
    OccurrenceNotFound(id) ->
      wisp.not_found()
      |> wisp.set_body(wisp.Text("Ocorrência não encontrada: " <> id))
  }
}
