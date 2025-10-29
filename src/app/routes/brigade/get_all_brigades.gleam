import app/routes/brigade/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
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
///     "name": "Brigada A",
///     "leader_name": "Pedro Anthony",
///     "is_active": true,
///   },
///   {
///     "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
///     "name": "Brigada B",
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

  case query_database(ctx:) {
    Error(err) -> handle_error(err)
    Ok(resp) -> wisp.json_response(resp, 200)
  }
}

fn handle_error(err: QueryAllBrigadesError) -> wisp.Response {
  case err {
    DataBaseError(err) -> web.handle_database_error(err)
  }
}

fn query_database(ctx ctx: Context) -> Result(String, QueryAllBrigadesError) {
  use returned <- result.try(
    sql.query_all_brigades(ctx.conn)
    |> result.map_error(DataBaseError),
  )

  // 󰅨  Return JSON array
  json.preprocessed_array({
    use row <- list.map(returned.rows)
    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("brigade_name", json.nullable(row.brigade_name, json.string)),
      #("leader_name", json.nullable(row.leader_name, json.string)),
      #("is_active", json.bool(row.is_active)),
    ])
  })
  |> json.to_string
  |> Ok
}

/// 󰤏  Querying a brigade can fail
type QueryAllBrigadesError {
  /// 󱙀  An error occurred while accessing the database
  DataBaseError(pog.QueryError)
}
