//// Handler for retrieving members from the same brigade as a given user.

import app/routes/role
import app/routes/user/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

/// 󰀖  Find all crew members or brigade members associated with a specific user
/// returns them as formatted JSON data.
///
/// ## Response
///
/// ```json
/// [
///    {
///      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
///      "full_name": "Ana Carolina Silva Santos",
///      "user_role": "bombeiro militar",
///      "brigade_id": "e134efdf-a131-4c4b-85ab-f4cb5146ec3f"
///    },
///    {
///      "id": "b2c3d4e5-f6g7-8901-bcde-f23456789012",
///      "full_name": "Carlos Eduardo Oliveira Pereira",
///      "user_role": "salva vidas",
///      "brigade_id": "e134efdf-a131-4c4b-85ab-f4cb5146ec3f"
///    },
///    {
///      "id": "c3d4e5f6-g7h8-9012-cdef-345678901234",
///      "full_name": "Mariana Costa Rodrigues",
///      "user_role": "bombeiro",
///      "brigade_id": "e134efdf-a131-4c4b-85ab-f4cb5146ec3f"
///    }
/// ]
/// ```
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

fn get_crew_members_row_to_json(row: sql.QueryCrewMembersRow) -> json.Json {
  let role_name =
    row.user_role
    |> enum_to_role()
    |> role.to_string_pt_br()

  json.object([
    #("id", json.string(uuid.to_string(row.id))),
    #("full_name", json.string(row.full_name)),
    #("user_role", json.string(role_name)),
    #("brigade_id", json.string(uuid.to_string(row.brigade_uuid))),
  ])
}

fn enum_to_role(user_role: sql.UserRoleEnum) -> role.Role {
  case user_role {
    sql.Admin -> role.Admin
    sql.Analist -> role.Analist
    sql.Captain -> role.Captain
    sql.Developer -> role.Developer
    sql.Firefighter -> role.Firefighter
    sql.Sargeant -> role.Sargeant
  }
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
