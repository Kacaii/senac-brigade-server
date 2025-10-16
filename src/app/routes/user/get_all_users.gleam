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

/// 󰀖  Queries the database for a complete list of all registered users and
/// returns them as a valid JSON reponse.
///
/// ```json
/// [
///   {
///     "id": "c3d4e5f6-g7h8-9012-cdef-345678901234",
///     "full_name": "Pedro Anthony",
///     "registration": "000",
///     "email": "pedro@email.com",
///     "user_role": "Bombeiro"
///   },
///   {
///     "id": "b2c3d4e5-f6g7-8901-bcde-f23456789012",
///     "full_name": "Josias Ribeiro",
///     "registration": "001",
///     "email": "jojo@email.com",
///     "user_role": "Desenvolvedor"
///    }
/// ]
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case try_query_database(req, ctx) {
    Error(err) -> handle_error(req, err)
    Ok(resp) -> wisp.json_response(json.to_string(resp), 200)
  }
}

fn handle_error(req: wisp.Request, err: GetAllUsersError) -> wisp.Response {
  case err {
    RoleError(err) -> handle_role_error(req, err)
    DataBaseError(err) -> handle_database_error(err)
  }
}

fn handle_role_error(
  req: wisp.Request,
  err: user.AuthorizationError,
) -> wisp.Response {
  case err {
    user.AuthenticationFailed(err) -> user.handle_authentication_error(err)
    user.FailedToQueryUserRole ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text(
        "Não foi possível identificar o cargo do usuário",
      ))
    user.InvalidRole(invalid) ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text("Usuário possui cargo inválido: " <> invalid))

    user.Unauthorized(user_uuid, user_role) -> {
      role.log_unauthorized_access_attempt(request: req, user_uuid:, user_role:)
      wisp.response(403)
      |> wisp.set_body(wisp.Text(
        "Acesso não autorizado: " <> role.to_string_pt_br(user_role),
      ))
    }
    user.DataBaseError(err) -> handle_database_error(err)
  }
}

fn handle_database_error(err: pog.QueryError) -> wisp.Response {
  let err_msg = case err {
    pog.ConnectionUnavailable -> "Conexão com o Banco de Dados não disponível"
    pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"
    _ -> "Ocorreu um erro ao consultar o Banco de Dados"
  }

  wisp.internal_server_error()
  |> wisp.set_body(wisp.Text(err_msg))
}

fn try_query_database(
  req: wisp.Request,
  ctx: Context,
) -> Result(json.Json, GetAllUsersError) {
  use _ <- result.try(
    user.check_role_authorization(
      request: req,
      ctx:,
      cookie_name: "USER_ID",
      authorized_roles: [role.Admin],
    )
    |> result.map_error(RoleError),
  )

  use returned <- result.map(
    sql.query_all_users(ctx.conn)
    |> result.map_error(DataBaseError),
  )

  //   Array containing all users
  json.preprocessed_array({
    use row <- list.map(returned.rows)
    row_to_json(row)
  })
}

fn row_to_json(row: sql.QueryAllUsersRow) -> json.Json {
  let user_role = {
    row.user_role
    |> enum_to_role()
    |> role.to_string_pt_br()
  }

  json.object([
    #("id", json.string(uuid.to_string(row.id))),
    #("full_name", json.string(row.full_name)),
    #("registration", json.string(row.registration)),
    #("email", json.nullable(row.email, json.string)),
    #("user_role", json.string(user_role)),
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

type GetAllUsersError {
  RoleError(user.AuthorizationError)
  DataBaseError(pog.QueryError)
}
