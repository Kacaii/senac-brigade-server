import app/routes/role
import app/routes/role/sql
import app/web
import app/web/context.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp

///   Find all available user roles and returns them as formatted JSON data
///
/// ## Response
///
/// ```json
/// {["desenvolvedor", "bombeiro", "capitão", "analista"]}
/// ```
///
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  // 󰡦  Find available roles
  case query_user_roles(ctx) {
    // Send data back to the Client
    Ok(role_list) -> wisp.json_response(json.to_string(role_list), 200)

    // Handle possible errors
    Error(err) -> handle_error(err)
  }
}

///   Gathering the role list can fail
type GetRoleListError {
  /// 󱘺  An error occurred while querying the DataBase
  DataBaseError(pog.QueryError)
}

fn handle_error(err: GetRoleListError) -> wisp.Response {
  case err {
    DataBaseError(err) -> web.handle_database_error(err)
  }
}

/// 󰆼  Queries the database to collect all available role names
fn query_user_roles(context: Context) -> Result(json.Json, GetRoleListError) {
  use returned <- result.try(
    sql.query_available_user_roles(context.conn)
    |> result.map_error(DataBaseError),
  )

  let available_roles =
    {
      use row <- list.map(returned.rows)
      row.available_role
      |> enum_to_role()
      |> role.to_string_pt_br()
      |> json.string
    }
    |> json.preprocessed_array

  Ok(available_roles)
}

fn enum_to_role(user_role: sql.UserRoleEnum) -> role.Role {
  case user_role {
    sql.Admin -> role.Admin
    sql.Analyst -> role.Analyst
    sql.Captain -> role.Captain
    sql.Developer -> role.Developer
    sql.Firefighter -> role.Firefighter
    sql.Sargeant -> role.Sargeant
  }
}
