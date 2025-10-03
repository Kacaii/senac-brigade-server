//// Handler for retrieving members of a specific fire brigade.
////
//// It returns a list of members belonging to the specified brigade, including
//// their id, full name, role, and description.

import app/routes/brigade/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
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

  let members_list_result = query_brigade_members(ctx, brigade_id)

  case members_list_result {
    Ok(members_list) -> wisp.json_response(json.to_string(members_list), 200)
    Error(err) -> handle_err(err)
  }
}

fn query_brigade_members(
  ctx: Context,
  brigade_id: String,
) -> Result(json.Json, GetBrigadeMembersError) {
  use brigade_uuid <- result.try(
    uuid.from_string(brigade_id)
    |> result.replace_error(InvalidUUID(brigade_id)),
  )
  use returned <- result.try(
    sql.query_brigade_members(ctx.conn, brigade_uuid)
    |> result.map_error(DataBaseError),
  )
  let members_list = {
    use row <- list.map(returned.rows)
    get_brigade_members_row_to_json(row)
  }

  Ok(json.preprocessed_array(members_list))
}

fn get_brigade_members_row_to_json(
  get_brigade_members_row: sql.QueryBrigadeMembersRow,
) -> json.Json {
  let sql.QueryBrigadeMembersRow(id:, full_name:, description:, role_name:) =
    get_brigade_members_row
  json.object([
    #("id", json.string(uuid.to_string(id))),
    #("full_name", json.string(full_name)),
    #("role_name", json.nullable(role_name, json.string)),
    #("description", json.nullable(description, json.string)),
  ])
}

fn handle_err(err: GetBrigadeMembersError) -> wisp.Response {
  case err {
    InvalidUUID(brigade_id) ->
      wisp.bad_request("ID de Brigada de Incêndio inválido:" <> brigade_id)
    DataBaseError(db_err) -> {
      let err_msg = case db_err {
        pog.ConnectionUnavailable ->
          "Conexão com o Banco de Dados não disponível"
        pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"
        _ -> "Ocorreu um erro ao realizar a consulta no Banco de Dados"
      }

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(err_msg))
    }
  }
}

/// Represents possible errors that can occur when retrieving brigade members
/// from the database
type GetBrigadeMembersError {
  /// The provided brigade ID is not a valid UUID format
  InvalidUUID(String)
  /// An error occurred while accessing the database to retrieve brigade members
  DataBaseError(pog.QueryError)
}
