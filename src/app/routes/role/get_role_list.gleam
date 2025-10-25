import app/routes/role
import app/routes/role/sql
import app/web.{type Context}
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
pub fn handle_request(request: wisp.Request, context: Context) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  // 󰡦  Find available roles
  case query_user_roles(context) {
    // Send data back to the Client
    Ok(role_list) -> wisp.json_response(json.to_string(role_list), 200)
    // Handle possible errors
    Error(err) -> handle_error(err)
  }
}

/// 󰆼  Queries the database to collect all available role names
fn query_user_roles(context: Context) -> Result(json.Json, GetRoleListError) {
  use returned <- result.try(
    sql.query_available_user_roles(context.conn)
    |> result.map_error(DataBaseError),
  )

  let available_roles = {
    use row <- list.map(returned.rows)
    let available_role =
      row.available_role
      |> enum_to_role()
      |> role.to_string_pt_br()

    json.string(available_role)
  }

  // 
  Ok(json.preprocessed_array(available_roles))
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

type GetRoleListError {
  DataBaseError(pog.QueryError)
}

fn handle_error(err: GetRoleListError) -> wisp.Response {
  let err_msg = case err {
    DataBaseError(pog.ConnectionUnavailable) ->
      "Conexão com o Banco de Dados não disponível"
    DataBaseError(pog.QueryTimeout) ->
      "O Banco de Dados demorou muito para responder"
    _ -> "Ocorreu um erro ao acessar o Banco de Dados"
  }

  wisp.internal_server_error()
  |> wisp.set_body(wisp.Text(err_msg))
}
