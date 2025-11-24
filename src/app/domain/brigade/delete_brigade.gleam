import app/domain/brigade/sql
import app/web
import app/web/context.{type Context}
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
    InvalidUuid(id) -> wisp.bad_request("Equipe possui UUID inválido: " <> id)
    BrigadeNotFound(id) -> wisp.bad_request("Equipe não econtrada: " <> id)
    DataBase(err) -> web.handle_database_error(err)
  }
}

fn delete_from_database(
  ctx: Context,
  id: String,
) -> Result(json.Json, DeleteBrigadeError) {
  use brigade_uuid <- result.try(
    uuid.from_string(id)
    |> result.replace_error(InvalidUuid(id)),
  )

  use returned <- result.try(
    sql.delete_brigade_by_id(ctx.db, brigade_uuid)
    |> result.map_error(DataBase),
  )
  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(BrigadeNotFound(id)),
  )

  json.object([
    #("id", json.string(uuid.to_string(row.id))),
    #("brigade_name", json.string(row.brigade_name)),
  ])
}

/// Deleting a brigade can fail
type DeleteBrigadeError {
  /// Session token has invalid Uuid fornmat
  InvalidUuid(String)
  /// An error occurred when accessing the DataBase
  DataBase(pog.QueryError)
  /// Brigade not found in the DataBase
  BrigadeNotFound(String)
}
