import app/routes/role
import app/routes/user
import app/routes/user/sql
import app/web.{type Context}
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

  case query_user_data(ctx, request) {
    Ok(user_data) -> wisp.json_response(json.to_string(user_data), 200)
    Error(err) -> handle_error(err)
  }
}

pub fn query_user_data(context: Context, request: wisp.Request) {
  use id <- result.try(
    user.auth_user_from_cookie(request:, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AuthenticationFailed),
  )

  use returned <- result.try(
    sql.query_user_profile(context.conn, id)
    |> result.map_error(DataBaseError),
  )
  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(DataBaseReturnedEmptyRow),
  )

  Ok(query_user_profile_row_to_json(row))
}

fn handle_error(err: GetUserProfileError) {
  case err {
    DataBaseError(db_err) -> {
      let err_message = case db_err {
        //   Connection failed
        pog.ConnectionUnavailable ->
          "Conexão com o Banco de Dados não disponível"

        //   Took too long
        pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"

        // Fallback
        _ -> "Ocorreu um erro ao localizar o usuário no Banco de Dados"
      }

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(err_message))
    }
    DataBaseReturnedEmptyRow -> wisp.bad_request("Usuário não cadastrado")
    AuthenticationFailed(auth_err) -> {
      case auth_err {
        user.InvalidUUID(user_id) ->
          wisp.bad_request("ID de usuário inválido: " <> user_id)

        // Deixar biscoito.
        user.MissingCookie -> wisp.bad_request("Cookie de autenticação ausente")
      }
    }
  }
}

fn query_user_profile_row_to_json(
  query_user_data_row: sql.QueryUserProfileRow,
) -> json.Json {
  let sql.QueryUserProfileRow(
    id:,
    full_name:,
    registration:,
    user_role:,
    email:,
    phone:,
  ) = query_user_data_row

  let user_role =
    user_role
    |> enum_to_role()
    |> role.to_string_pt_br()

  json.object([
    #("id", json.string(uuid.to_string(id))),
    #("full_name", json.string(full_name)),
    #("registration", json.string(registration)),
    #("user_role", json.string(user_role)),
    #("email", json.nullable(email, json.string)),
    #("phone", json.nullable(phone, json.string)),
  ])
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

pub type GetUserProfileError {
  DataBaseError(pog.QueryError)
  DataBaseReturnedEmptyRow
  AuthenticationFailed(user.AuthenticationError)
}
