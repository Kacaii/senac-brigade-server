import app/routes/dashboard/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp

// TODO: Docs
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  let query_result = {
    use returned <- result.try(
      sql.get_dashboard_stats(ctx.conn)
      |> result.map_error(DatabaseError),
    )
    use row <- result.try(
      list.first(returned.rows)
      |> result.replace_error(DatabaseReturnedEmptyRow),
    )

    Ok(get_dashboard_stats_row_to_json(row))
  }

  case query_result {
    Ok(value) -> wisp.json_response(json.to_string(value), 200)
    Error(err) -> {
      case err {
        DatabaseReturnedEmptyRow -> {
          wisp.internal_server_error()
          |> wisp.set_body(wisp.Text("O Banco de dados não retornou resultados"))
        }
        DatabaseError(err) -> {
          let err_message = case err {
            pog.ConnectionUnavailable ->
              "Conexão com o Banco de Dados não disponível"
            pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"
            _ -> "Ocorreu um erro ao acessar o Banco de Dados"
          }

          wisp.internal_server_error()
          |> wisp.set_body(wisp.Text(err_message))
        }
      }
    }
  }
}

fn get_dashboard_stats_row_to_json(
  get_dashboard_stats_row: sql.GetDashboardStatsRow,
) -> json.Json {
  let sql.GetDashboardStatsRow(
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

pub type GetDashboardStatsError {
  DatabaseReturnedEmptyRow
  DatabaseError(pog.QueryError)
}
