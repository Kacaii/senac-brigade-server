import app/domain/brigade/sql
import app/web
import app/web/context.{type Context}
import gleam/http
import gleam/json
import gleam/result
import pog
import wisp
import youid/uuid

/// 󰡦  Find all brigades registered on the DataBase
/// and return details as formatted JSON response
///
/// It doesnt return their members. Use a separate enpoint instead
///
/// ## Response
///
/// ```json
/// [
///   {
///     "id": "c3d4e5f6-g7h8-9012-cdef-345678901234",
///     "brigade_name": "Brigada A",
///     "leader_name": "Pedro Anthony",
///     "is_active": true,
///   },
///   {
///     "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
///     "brigade_name": "Brigada B",
///     "leader_name": "Anderson Silva",
///     "is_active": false,
///   }
/// ]
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case query_database(ctx) {
    Error(err) -> handle_error(err)
    Ok(resp) -> wisp.json_response(resp, 200)
  }
}

fn handle_error(err: QueryAllBrigadesError) -> wisp.Response {
  case err {
    DataBase(err) -> web.handle_database_error(err)
  }
}

fn query_database(ctx: Context) -> Result(String, QueryAllBrigadesError) {
  use returned <- result.map(
    sql.query_all_brigades(ctx.db)
    |> result.map_error(DataBase),
  )

  returned.rows
  |> json.array(row_to_json)
  |> json.to_string
}

fn row_to_json(row: sql.QueryAllBrigadesRow) {
  json.object([
    #("id", json.string(uuid.to_string(row.id))),
    #("brigade_name", json.string(row.brigade_name)),
    #("leader_name", json.nullable(row.leader_name, json.string)),
    #("is_active", json.bool(row.is_active)),
  ])
}

/// 󰤏  Querying a brigade can fail
type QueryAllBrigadesError {
  /// 󱙀  An error occurred while accessing the database
  DataBase(pog.QueryError)
}
