import app/routes/notification
import app/routes/notification/sql
import app/routes/user
import app/web.{type Context}
import gleam/dict
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp

/// 󰚰  Updates the notification preferences from an user
/// and returs them as formatted JSON data
///
/// ## Response
///
/// ```json
/// {
///    "message": "Preferências de notificação atualizadas com sucesso",
///    "data": {
///      "incendio": true,
///      "emergencia": false,
///      "transito": true,
///      "outros": false
///    }
/// }
/// ```
pub fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Put)
  use json_data <- wisp.require_json(req)

  case notification_preferences_decoder(json_data) {
    Error(_) -> wisp.bad_request("Solicitação inválida")
    Ok(form_data) -> {
      case update_preferences(req, ctx, form_data) {
        Error(err) -> handle_err(err)
        Ok(_) -> {
          let resp = {
            let data = json.dict(form_data, notification.to_string, json.bool)
            let message =
              json.string("Preferências de notificação atualizadas com sucesso")

            json.object([#("message", message), #("data", data)])
          }

          wisp.json_response(json.to_string(resp), 200)
        }
      }
    }
  }
}

fn notification_preferences_decoder(
  data: decode.Dynamic,
) -> Result(NotificationPreferences, List(decode.DecodeError)) {
  let schema = {
    use fire_enabled <- decode.field("incendio", decode.bool)
    use emergency_enabled <- decode.field("emergencia", decode.bool)
    use traffic <- decode.field("transito", decode.bool)
    use other <- decode.field("outros", decode.bool)

    decode.success(
      dict.from_list([
        #(sql.Fire, fire_enabled),
        #(sql.Emergency, emergency_enabled),
        #(sql.Traffic, traffic),
        #(sql.Other, other),
      ]),
    )
  }

  decode.run(data, schema)
}

fn handle_err(err: UpdateNotificationPreferencesError) -> wisp.Response {
  case err {
    AuthenticationFailed(err) -> user.handle_authentication_error(err)
    DataBaseError(err) -> {
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

fn update_preferences(
  req: wisp.Request,
  ctx: Context,
  preferences: NotificationPreferences,
) -> Result(List(pog.Returned(Nil)), UpdateNotificationPreferencesError) {
  use user_uuid <- result.try(
    user.auth_user_from_cookie(request: req, cookie_name: "USER_ID")
    |> result.map_error(AuthenticationFailed),
  )

  use update_result <- result.try({
    use #(key, value) <- list.try_map(dict.to_list(preferences))
    sql.update_notification_preferences(ctx.conn, user_uuid, key, value)
    |> result.map_error(DataBaseError)
  })

  Ok(update_result)
}

type NotificationPreferences =
  dict.Dict(sql.NotificationTypeEnum, Bool)

type UpdateNotificationPreferencesError {
  AuthenticationFailed(user.AuthenticationError)
  DataBaseError(pog.QueryError)
}
