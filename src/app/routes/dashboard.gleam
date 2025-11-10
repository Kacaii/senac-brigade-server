import app/routes/dashboard/sql
import app/web
import app/web/context.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp

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

  case get_dashboard_data(ctx:) {
    Ok(value) -> wisp.json_response(json.to_string(value), 200)
    Error(err) -> handle_error(err:)
  }
}

fn get_dashboard_data(
  ctx ctx: Context,
) -> Result(json.Json, GetDashboardStatsError) {
  //  QUERY THE DATABASE ----------------------------------------------------
  use returned <- result.try(
    sql.query_dashboard_stats(ctx.db)
    |> result.map_error(DataBaseError),
  )
  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(DataBaseReturnedNoResults),
  )

  Ok(get_dashboard_stats_row_to_json(row))
}

fn handle_error(err err: GetDashboardStatsError) -> wisp.Response {
  case err {
    // 󱋬  DataBase couldn't find the required information for the dashboard
    DataBaseReturnedNoResults -> {
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "O Banco de dados não encontrou os dados solicitados",
      ))
    }

    DataBaseError(err) -> web.handle_database_error(err)
  }
}

fn get_dashboard_stats_row_to_json(
  get_dashboard_stats_row: sql.QueryDashboardStatsRow,
) -> json.Json {
  let sql.QueryDashboardStatsRow(
    active_brigades_count:,
    total_occurrences_count:,
    active_occurrences_count:,
    recent_occurrences_count:,
  ) = get_dashboard_stats_row
  json.object([
    #("totalOcorrencias", json.int(total_occurrences_count)),
    #("ocorrenciasHoje", json.int(recent_occurrences_count)),
    #("emAndamento", json.int(active_occurrences_count)),
    #("equipesAtivas", json.int(active_brigades_count)),
  ])
}

/// Querying the endpoint can fail
pub type GetDashboardStatsError {
  /// DataBase could not find the data
  DataBaseReturnedNoResults
  /// DataBase query went wrong
  DataBaseError(pog.QueryError)
}
