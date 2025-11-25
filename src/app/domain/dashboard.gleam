import app/domain/dashboard/sql
import app/web
import app/web/context.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp

pub type GetDashboardStatsError {
  ///   Found no results
  NotFound
  /// 󰆼  Failed to query the DataBase
  DataBase(pog.QueryError)
}

/// 󰡦  Retrieve dashboard stats from the DataBase and returns them
/// as formatted JSON data
///
/// ## Response
///
/// ```json
/// {
///   "totalOcorrencias": 0,
///   "ocorrenciasHoje": 0,
///   "emAndamento": 0,
///   "equipesAtivas": 0
/// }
/// ```
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  case query_dashboard_stats(ctx) {
    Ok(body) -> wisp.json_response(body, 200)
    Error(err) -> handle_error(err)
  }
}

fn query_dashboard_stats(ctx: Context) -> Result(String, GetDashboardStatsError) {
  use returned <- result.try(
    sql.query_dashboard_stats(ctx.db)
    |> result.map_error(DataBase),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(NotFound),
  )

  row
  |> row_to_json
  |> json.to_string
}

fn handle_error(err: GetDashboardStatsError) -> wisp.Response {
  case err {
    NotFound ->
      "O Banco de dados não encontrou os dados solicitados"
      |> wisp.Text()
      |> wisp.set_body(wisp.not_found(), _)

    DataBase(err) -> web.handle_database_error(err)
  }
}

fn row_to_json(row: sql.QueryDashboardStatsRow) -> json.Json {
  json.object([
    #("totalOcorrencias", json.int(row.total_occurrences_count)),
    #("ocorrenciasHoje", json.int(row.recent_occurrences_count)),
    #("emAndamento", json.int(row.active_occurrences_count)),
    #("equipesAtivas", json.int(row.active_brigades_count)),
  ])
}
