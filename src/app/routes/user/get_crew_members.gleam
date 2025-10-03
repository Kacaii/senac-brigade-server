//// Handler for retrieving members from the same brigade as a given user.

import app/routes/user/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import wisp
import youid/uuid

/// Retrieves all crew members or brigade members associated with a specific user
/// from the database and returns them as formatted JSON data.
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id user_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let query_result = {
    use user_uuid <- result.try(
      uuid.from_string(user_id)
      |> result.replace_error(InvalidUUID),
    )
    use returned <- result.try(
      sql.get_crew_members(ctx.conn, user_uuid)
      |> result.replace_error(DataBaseError),
    )
    let fellow_members_list = {
      use fellow_brigade_member <- list.map(returned.rows)
      get_crew_members_row_to_json(fellow_brigade_member)
    }

    Ok(json.preprocessed_array(fellow_members_list))
  }

  case query_result {
    Ok(fellow_members_list) ->
      wisp.json_response(json.to_string(fellow_members_list), 200)

    Error(err) -> {
      let error_message = case err {
        DataBaseError -> "Ocorreu um erro ao acessar o Banco de Dados"
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

fn get_crew_members_row_to_json(
  get_crew_members_row: sql.GetCrewMembersRow,
) -> json.Json {
  let sql.GetCrewMembersRow(id:, full_name:, role_name:, description:) =
    get_crew_members_row
  json.object([
    #("id", json.string(uuid.to_string(id))),
    #("full_name", json.string(full_name)),
    #("role_name", json.string(option.unwrap(role_name, ""))),
    #("description", json.string(option.unwrap(description, ""))),
  ])
}
