//// Handler for retrieving members of a specific fire brigade.
////
//// It returns a list of members belonging to the specified brigade, including
//// their id, full name, role, and description.

import app/routes/brigade/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import wisp
import youid/uuid

/// Retrieves all members of a specific fire brigade from the database
/// and returns them as formatted JSON data.
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
  id brigade_id: String,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

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
  let sql.GetBrigadeMembersRow(id:, full_name:, description:, role_name:) =
    get_brigade_members_row
  json.object([
    #("id", json.string(uuid.to_string(id))),
    #("full_name", json.string(full_name)),
    #("role_name", json.string(option.unwrap(role_name, ""))),
    #("description", json.string(option.unwrap(description, ""))),
  ])
}

/// Represents possible errors that can occur when retrieving brigade members
/// from the database
type GetBrigadeMembersError {
  /// The provided brigade ID is not a valid UUID format
  InvalidUUID
  /// An error occurred while accessing the database to retrieve brigade members
  DataBaseError
}
