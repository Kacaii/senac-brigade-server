import app/routes/role/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp

pub fn handle_request(request: wisp.Request, context: Context) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  let query_result = {
    use returned <- result.try(
      sql.query_role_list(context.conn)
      |> result.map_error(DataBaseError),
    )

    let available_roles = {
      use row <- list.map(returned.rows)
      json.string(row.role_name)
    }

    Ok(json.preprocessed_array(available_roles))
  }

  case query_result {
    Ok(role_list) -> wisp.json_response(json.to_string(role_list), 200)
    Error(err) -> {
      case err {
        DataBaseError(db_err) -> {
          let err_msg = case db_err {
            pog.ConnectionUnavailable ->
              "Conexão com o banco de dados não disponível"
            pog.QueryTimeout -> "O banco de dados demorou muito para responder"
            _ -> "Ocorreu um erro ao acessar o Banco de Dados"
          }

          wisp.internal_server_error()
          |> wisp.set_body(wisp.Text(err_msg))
        }
      }
    }
  }
}

type GetRoleListErrors {
  DataBaseError(pog.QueryError)
}
