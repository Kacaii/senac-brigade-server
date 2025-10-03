//// Handler for retrieving members from the same brigade as a given user.

import app/routes/user/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
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

  let query_result = query_crew_members(ctx:, user_id:)

  case query_result {
    Ok(fellow_members_list) ->
      wisp.json_response(json.to_string(fellow_members_list), 200)

    Error(err) -> handle_err(err)
  }
}

fn query_crew_members(ctx ctx: Context, user_id user_id: String) {
  use user_uuid <- result.try(
    uuid.from_string(user_id)
    |> result.replace_error(InvalidUUID(user_id)),
  )
  use returned <- result.try(
    sql.query_crew_members(ctx.conn, user_uuid)
    |> result.map_error(DataBaseError),
  )
  let fellow_members_list = {
    use fellow_brigade_member <- list.map(returned.rows)
    get_crew_members_row_to_json(fellow_brigade_member)
  }

  Ok(json.preprocessed_array(fellow_members_list))
}

fn get_crew_members_row_to_json(
  get_crew_members_row: sql.QueryCrewMembersRow,
) -> json.Json {
  let sql.QueryCrewMembersRow(id:, full_name:, role_name:, description:) =
    get_crew_members_row
  json.object([
    #("id", json.string(uuid.to_string(id))),
    #("full_name", json.string(full_name)),
    #("role_name", json.nullable(role_name, json.string)),
    #("description", json.nullable(description, json.string)),
  ])
}

fn handle_err(err: GetFellowBrigadeMembersError) {
  let error_message = case err {
    InvalidUUID(user_id) -> "ID de usuário inválido: " <> user_id
    DataBaseError(db_err) -> {
      case db_err {
        pog.ConnectionUnavailable ->
          "Conexão com o Banco de Dados não disponível"
        pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"
        _ -> "Ocorreu um erro ao realizar a consulta no Banco de Dados"
      }
    }
  }

  wisp.internal_server_error()
  |> wisp.set_body(wisp.Text(error_message))
}

type GetFellowBrigadeMembersError {
  DataBaseError(pog.QueryError)
  InvalidUUID(String)
}
