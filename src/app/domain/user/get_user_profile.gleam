import app/domain/role
import app/domain/user
import app/domain/user/sql
import app/web
import app/web/context.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

/// 󰡦  Find information about the current authenticated user
/// and returs them as formatted JSON data
///
/// User UUID is extracted from the request `Cookies`
///
/// ```json
/// {
///    "id": "b2c3d4e5-f6g7-8901-bcde-f23456789012",
///    "full_name": "Maria Oliveira Costa",
///    "registration": "000000",
///    "user_role": "Desenvolvedor",
///    "email": "maria.oliveira@empresa.com.br",
///    "phone": "+55 (81) 9 8888-8888"
/// }
/// ```
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  // 󰡦  Query the database
  case query_user_data(ctx, request) {
    //   Handle possible errors
    Error(err) -> handle_error(err)
    // 󱃜  Send the response to the client
    Ok(body) -> wisp.json_response(body, 200)
  }
}

///   Finding information about an user profile can fail
pub type GetUserProfileError {
  /// 󱙀  An error occurred while accessing the database
  DataBase(pog.QueryError)
  ///   User not found in the DataBase
  UserNotFound(uuid.Uuid)
  ///   Authentication failed
  AccessControl(user.AuthenticationError)
}

fn handle_error(err: GetUserProfileError) {
  case err {
    AccessControl(err) -> user.handle_authentication_error(err)
    DataBase(err) -> web.handle_database_error(err)
    UserNotFound(id) -> {
      // HTTP 404 Not Found
      let resp = wisp.not_found()
      let body = "Usuário não cadastrado: " <> uuid.to_string(id)

      wisp.Text(body)
      |> wisp.set_body(resp, _)
    }
  }
}

pub fn query_user_data(ctx: Context, request: wisp.Request) {
  use user_id <- result.try(
    user.extract_uuid(request:, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AccessControl),
  )

  use returned <- result.try(
    sql.query_user_profile(ctx.db, user_id)
    |> result.map_error(DataBase),
  )

  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(UserNotFound(user_id)),
  )

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
    #("registration", json.string(row.registration)),
    #("user_role", json.string(user_role)),
    #("email", json.string(row.email)),
    #("phone", json.nullable(row.phone, json.string)),
  ])
  |> json.to_string
  |> Ok
}
