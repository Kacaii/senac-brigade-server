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

pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id user_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)

  case try_delete_user(req, ctx, user_id) {
    Ok(deleted_user) -> wisp.json_response(json.to_string(deleted_user), 200)
    Error(err) -> handle_error(req, err)
  }
}

fn handle_error(req: wisp.Request, err: DeleteUserError) -> wisp.Response {
  case err {
    InvalidUserUuid(invalid_uuid) ->
      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text(
        "Usuário possui Uuid Inválido: " <> invalid_uuid,
      ))
    MissingDeleteConfirmation ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "Não foi possível confirmar a remoção do usuário solicitado",
      ))
    RoleError(err) -> handle_role_error(req, err)
    DataBaseError(err) -> handle_database_error(err)
  }
}

fn handle_role_error(
  req: wisp.Request,
  err: user.AuthorizationError,
) -> wisp.Response {
  case err {
    user.Unauthorized(user_uuid, user_role) -> {
      role.log_unauthorized_access_attempt(request: req, user_uuid:, user_role:)

      wisp.response(403)
      |> wisp.set_body(wisp.Text(
        "Acesso não autorizado: " <> role.to_string_pt_br(user_role),
      ))
    }
    user.AuthenticationFailed(err) -> user.handle_authentication_error(err)
    user.DataBaseError(err) -> handle_database_error(err)
    user.FailedToQueryUserRole ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text(
        "Não foi possível consultar o cargo do usuário autenticado",
      ))
    user.InvalidRole(invalid) ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text("Usuário possui cargo inválido: " <> invalid))
  }
}

fn handle_database_error(err: pog.QueryError) -> wisp.Response {
  let err_msg = case err {
    pog.ConnectionUnavailable -> "Conexão com o Banco de Dados não disponível"
    pog.ConstraintViolated(message:, constraint:, detail:) ->
      constraint <> ": " <> message <> "\n" <> detail
    pog.PostgresqlError(code:, name:, message:) ->
      code <> ": " <> name <> ": " <> "\n" <> message
    pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"
    _ -> "Ocorreu um erro ao acessar o Banco de Dados"
  }

  wisp.internal_server_error()
  |> wisp.set_body(wisp.Text(err_msg))
}

fn try_delete_user(
  req: wisp.Request,
  ctx: Context,
  id: String,
) -> Result(json.Json, DeleteUserError) {
  use target_user_uuid <- result.try(
    uuid.from_string(id)
    |> result.replace_error(InvalidUserUuid(id)),
  )
  use _ <- result.try(
    user.check_role_authorization(
      request: req,
      ctx:,
      cookie_name: "USER_ID",
      authorized_roles: [role.Admin],
    )
    |> result.map_error(RoleError),
  )
  use returned <- result.try(
    sql.delete_user_by_id(ctx.conn, target_user_uuid)
    |> result.map_error(DataBaseError),
  )
  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(MissingDeleteConfirmation),
  )

  json.object([
    #("id", json.string(uuid.to_string(row.id))),
    #("full_name", json.string(row.full_name)),
  ])
}

type DeleteUserError {
  DataBaseError(pog.QueryError)
  InvalidUserUuid(String)
  RoleError(user.AuthorizationError)
  MissingDeleteConfirmation
}
