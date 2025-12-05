import app/domain/role
import app/domain/role/sql
import app/web
import app/web/context.{type Context}
import gleam/http
import gleam/json
import gleam/result
import pog
import wisp

///   Find all available user roles and returns them as formatted JSON data
///
/// ## Response
///
/// ```json
/// ["desenvolvedor", "bombeiro", "capitão", "analista"]
/// ```
///
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  case query_user_roles(ctx) {
    Ok(body) -> wisp.json_response(body, 200)
    Error(err) -> handle_error(err)
  }
}

type GetRoleListError {
  /// Failed to query the DataBase
  DataBase(pog.QueryError)
}

fn handle_error(err: GetRoleListError) -> wisp.Response {
  case err {
    DataBase(err) -> web.handle_database_error(err)
  }
}

/// 󰆼  Queries the database to collect all available role names
fn query_user_roles(ctx: Context) -> Result(String, GetRoleListError) {
  use returned <- result.map(
    sql.query_available_user_roles(ctx.db)
    |> result.map_error(DataBase),
  )

  let enum_to_role = fn(role: sql.UserRoleEnum) {
    case role {
      sql.Admin -> role.Admin
      sql.Analyst -> role.Analyst
      sql.Captain -> role.Captain
      sql.Developer -> role.Developer
      sql.Firefighter -> role.Firefighter
      sql.Sargeant -> role.Sargeant
    }
  }

  let row_to_json = fn(row: sql.QueryAvailableUserRolesRow) {
    row.available_role
    |> enum_to_role()
    |> role.to_string_pt_br()
    |> json.string
  }

  returned.rows
  |> json.array(row_to_json)
  |> json.to_string
}
