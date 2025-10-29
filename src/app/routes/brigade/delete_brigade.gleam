import app/routes/brigade/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

///   Remove a brigade from the DataBase and return
/// information about the deleted brigade as formatted JSON
///
/// ## Response
///
/// ```json
/// {
///   "id": "c3d4e5f6-g7h8-9012-cdef-345678901234",
///   "brigade_name": "Brigada ABC"
/// }
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id brigade_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)

  case delete_from_database(ctx, brigade_id) {
    Error(err) -> handle_error(err)
    Ok(removed) -> wisp.json_response(json.to_string(removed), 200)
  }
}

fn handle_error(err: DeleteBrigadeError) -> wisp.Response {
  case err {
    InvalidBrigadeUuid(id) ->
      wisp.bad_request("Equipe possui UUID inválido: " <> id)
    UuidNotFound(id) -> wisp.bad_request("Equipe não econtrada: " <> id)
    DataBaseError(err) -> web.handle_database_error(err)
  }
}

fn delete_from_database(
  ctx: Context,
  id: String,
) -> Result(json.Json, DeleteBrigadeError) {
  use brigade_uuid <- result.try(
    uuid.from_string(id) |> result.replace_error(InvalidBrigadeUuid(id)),
  )
  use returned <- result.try(
    sql.delete_brigade_by_id(ctx.conn, brigade_uuid)
    |> result.map_error(DataBaseError),
  )
  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(UuidNotFound(id)),
  )

  json.object([
    #("id", json.string(uuid.to_string(row.id))),
    #("brigade_name", json.string(row.brigade_name)),
  ])
}

type DeleteBrigadeError {
  InvalidBrigadeUuid(String)
  DataBaseError(pog.QueryError)
  UuidNotFound(String)
}
