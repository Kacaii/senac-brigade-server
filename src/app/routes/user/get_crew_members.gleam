//// Handler for retrieving members from the same brigade as a given user.

import app/routes/role
import app/routes/user/sql
import app/web
import app/web/context.{type Context}
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

  case try_query_database(ctx:, user_id:) {
    Ok(body) -> wisp.json_response(body, 200)
    Error(err) -> handle_err(err)
  }
}

fn try_query_database(
  ctx ctx: Context,
  user_id user_id: String,
) -> Result(String, GetCrewMembersError) {
  use user_uuid <- result.try(
    uuid.from_string(user_id)
    |> result.replace_error(InvalidUUID(user_id)),
  )

  use returned <- result.try(
    sql.query_crew_members(ctx.db, user_uuid)
    |> result.map_error(DataBase),
  )

  let fellow_members_list = {
    use fellow_brigade_member <- list.map(returned.rows)
    get_crew_members_row_to_json(fellow_brigade_member)
  }

  json.preprocessed_array(fellow_members_list)
  |> json.to_string
  |> Ok
}

fn get_crew_members_row_to_json(row: sql.QueryCrewMembersRow) -> json.Json {
  let role_name =
    role.to_string_pt_br(case row.user_role {
      sql.Admin -> role.Admin
      sql.Analyst -> role.Analyst
      sql.Captain -> role.Captain
      sql.Developer -> role.Developer
      sql.Firefighter -> role.Firefighter
      sql.Sargeant -> role.Sargeant
    })

  json.object([
    #("id", json.string(uuid.to_string(row.id))),
    #("full_name", json.string(row.full_name)),
    #("user_role", json.string(role_name)),
    #("brigade_id", json.string(uuid.to_string(row.brigade_id))),
  ])
}

fn handle_err(err: GetCrewMembersError) {
  case err {
    InvalidUUID(id) -> wisp.bad_request("ID de usuário inválido: " <> id)
    DataBase(err) -> web.handle_database_error(err)
  }
}

/// Finding the user's crew can fail
type GetCrewMembersError {
  /// User has invalid Uuid fornmat
  InvalidUUID(String)
  /// An error occurred while accessing the DataBase
  DataBase(pog.QueryError)
}
