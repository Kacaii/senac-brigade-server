import app/routes/notification
import app/routes/notification/sql
import app/routes/user
import app/web.{type Context}
import gleam/dict
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp

/// 󰀖  Find the notification preferences from an user
/// and send them as formatted JSON data
///
/// ## Response
///
/// ```json
/// {
///    "incendio": false,
///    "emergencia": false,
///    "transito": false,
///    "outros": false
/// }
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case query_database(req, ctx) {
    Error(err) -> handle_error(err)
    Ok(preferences) -> wisp.json_response(json.to_string(preferences), 200)
  }
}

fn handle_error(err: GetNotificationPreferencesError) -> wisp.Response {
  case err {
    AuthenticationFailed(err) -> user.handle_authentication_error(err)
    DataBaseReturnedEmptyRow ->
      wisp.bad_request("O Banco de Dados não retornou resultados")
    DatabaseError(err) -> {
      let err_message = case err {
        //
        //   Connection failed
        pog.ConnectionUnavailable ->
          "Conexão com o Banco de Dados não disponível"

        //   Took too long
        pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"

        // Fallback
        _ -> "Ocorreu um erro ao acessar o Banco de Dados"
      }

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(err_message))
    }
  }
}

fn query_database(
  req: wisp.Request,
  ctx: Context,
) -> Result(json.Json, GetNotificationPreferencesError) {
  use user_uuid <- result.try(
    user.auth_user_from_cookie(request: req, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AuthenticationFailed),
  )

  use returned <- result.try(
    sql.query_notification_preferences(ctx.conn, user_uuid)
    |> result.map_error(DatabaseError),
  )

  let preferences = {
    use acc, row <- list.fold(returned.rows, dict.new())
    dict.insert(acc, row.notification_type, row.enabled)
  }

  Ok(json.dict(preferences, notification.to_string_pt_br, json.bool))
}

type GetNotificationPreferencesError {
  DataBaseReturnedEmptyRow
  AuthenticationFailed(user.AuthenticationError)
  DatabaseError(pog.QueryError)
}
