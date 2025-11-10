//// Handler for retrieving members of a specific fire brigade.
////
//// It returns a list of members belonging to the specified brigade, including
//// their id, full name, role, and description.

import app/routes/brigade/sql
import app/routes/role
import app/web
import app/web/context.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

/// 󰀖  Find all members of a specific brigade from the DataBase
/// and returns them as formatted JSON data.
///
/// ## Response
///
/// ```json
/// [
///    {
///      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
///      "full_name": "Ana Carolina Silva Santos",
///      "user_role": "bombeiro militar",
///    },
///    {
///      "id": "b2c3d4e5-f6g7-8901-bcde-f23456789012",
///      "full_name": "Carlos Eduardo Oliveira Pereira",
///      "user_role": "salva vidas",
///    },
///    {
///      "id": "c3d4e5f6-g7h8-9012-cdef-345678901234",
///      "full_name": "Mariana Costa Rodrigues",
///      "user_role": "bombeiro",
///    }
/// ]
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
  id brigade_id: String,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  case query_brigade_members(ctx, brigade_id) {
    Ok(body) -> wisp.json_response(body, 200)
    Error(err) -> handle_error(err)
  }
}

/// Represents possible errors that can occur when retrieving brigade members
/// from the database
type GetBrigadeMembersError {
  /// 󱔼  The provided brigade ID is not a valid UUID format
  InvalidUUID(String)
  /// 󱙀  An error occurred while accessing the database
  DataBaseError(pog.QueryError)
}

fn handle_error(err: GetBrigadeMembersError) -> wisp.Response {
  case err {
    InvalidUUID(id) ->
      wisp.bad_request("ID de Brigada de Incêndio inválido:" <> id)
    DataBaseError(err) -> web.handle_database_error(err)
  }
}

fn query_brigade_members(
  ctx: Context,
  brigade_id: String,
) -> Result(String, GetBrigadeMembersError) {
  use brigade_uuid <- result.try(
    uuid.from_string(brigade_id)
    |> result.replace_error(InvalidUUID(brigade_id)),
  )

  use returned <- result.try(
    sql.query_members_info(ctx.db, brigade_uuid)
    |> result.map_error(DataBaseError),
  )

  // Building response body
  json.preprocessed_array({
    use row <- list.map(returned.rows)
    let user_role =
      case row.user_role {
        sql.Admin -> role.Admin
        sql.Analyst -> role.Analyst
        sql.Captain -> role.Captain
        sql.Developer -> role.Developer
        sql.Firefighter -> role.Firefighter
        sql.Sargeant -> role.Sargeant
      }
      |> role.to_string_pt_br()

    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("full_name", json.string(row.full_name)),
      #("user_role", json.string(user_role)),
    ])
  })
  |> json.to_string
  |> Ok
}
