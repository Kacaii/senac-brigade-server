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
  req req: wisp.Request,
  ctx ctx: Context,
  user_id user_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let query_result = {
    use user_uuid <- result.try(
      uuid.from_string(user_id)
      |> result.replace_error(InvalidUUID),
    )
    use returned <- result.try(
      sql.get_fellow_brigade_members(ctx.conn, user_uuid)
      |> result.replace_error(DataBaseError),
    )
    let fellow_members_list = {
      use fellow_brigade_member <- list.map(returned.rows)
      get_fellow_brigade_members_row_to_json(fellow_brigade_member)
    }

    Ok(json.preprocessed_array(fellow_members_list))
  }

  case query_result {
    Ok(fellow_members_list) ->
      wisp.json_response(json.to_string(fellow_members_list), 200)

    Error(err) -> {
      let error_message = case err {
        DataBaseError -> "Ocorreu um erro ao acessar o banco de dados"
        InvalidUUID -> "ID de usuário inválido"
      }

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(error_message))
    }
  }
}

type GetFellowBrigadeMembersError {
  DataBaseError
  InvalidUUID
}

fn get_fellow_brigade_members_row_to_json(
  get_fellow_brigade_members_row: sql.GetFellowBrigadeMembersRow,
) -> json.Json {
  let sql.GetFellowBrigadeMembersRow(full_name:, role_name:, description:) =
    get_fellow_brigade_members_row
  json.object([
    #("full_name", json.string(full_name)),
    #("role_name", json.string(option.unwrap(role_name, ""))),
    #("description", json.string(option.unwrap(description, ""))),
  ])
}
