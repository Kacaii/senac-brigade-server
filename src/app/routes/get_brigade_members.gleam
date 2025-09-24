import app/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import wisp
import youid/uuid

pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  brigade_id brigade_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let members_list_result = {
    use brigade_id <- result.try(
      uuid.from_string(brigade_id)
      |> result.replace_error(InvalidUUID),
    )
    use returned <- result.try(
      sql.get_brigade_members(ctx.conn, brigade_id)
      |> result.replace_error(DataBaseError),
    )
    let members_list = {
      use row <- list.map(returned.rows)
      get_brigade_members_row_to_json(row)
    }

    Ok(json.preprocessed_array(members_list))
  }

  case members_list_result {
    Ok(members_list) -> wisp.json_response(json.to_string(members_list), 200)
    Error(err) -> {
      let error_message = case err {
        DataBaseError -> "Ocorreu um erro ao acessar o banco de dados"
        InvalidUUID -> "ID de brigada de incêndio inválido"
      }

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(error_message))
    }
  }
}

fn get_brigade_members_row_to_json(
  get_brigade_members_row: sql.GetBrigadeMembersRow,
) -> json.Json {
  let sql.GetBrigadeMembersRow(full_name:, description:, role_name:) =
    get_brigade_members_row
  json.object([
    #("full_name", json.string(full_name)),
    #("role_name", json.string(option.unwrap(role_name, ""))),
    #("description", json.string(option.unwrap(description, ""))),
  ])
}

type GetBrigadeMembersError {
  InvalidUUID
  DataBaseError
}
