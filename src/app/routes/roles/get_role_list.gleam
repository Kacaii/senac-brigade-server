import app/routes/roles/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import wisp

pub fn handle_request(request: wisp.Request, context: Context) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  let query_result = {
    use returned <- result.try(
      sql.roles(context.conn) |> result.replace_error(DataBaseError),
    )

    let list_roles = {
      list.map(returned.rows, fn(role) { roles_row_to_json(role) })
    }

    Ok(json.preprocessed_array(list_roles))
  }
  case query_result {
    Ok(value) -> {
      wisp.json_response(json.to_string(value), 200)
    }
    Error(value) -> {
      case value {
        DataBaseError -> wisp.internal_server_error()
      }
    }
  }
}

fn roles_row_to_json(roles_row: sql.RolesRow) -> json.Json {
  let sql.RolesRow(role_name:) = roles_row
  json.object([
    #("role_name", json.string(role_name)),
  ])
}

type RolesErros {
  DataBaseError
}
