import app/routes/notification/sql
import app/routes/occurrence/category
import app/routes/user
import app/web
import app/web/context.{type Context}
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
///   "incendio": true,
///   "emergencia": false,
///   "transito": true,
///   "outros": false
/// }
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Put)
  use json_data <- wisp.require_json(req)

  case notification_preferences_decoder(json_data) {
    Error(_) -> wisp.bad_request("Solicitação inválida")
    Ok(form_data) -> {
      case update_preferences(req, ctx, form_data) {
        Error(err) -> handle_err(err)
        Ok(_) -> {
          let data = json.dict(form_data, category.to_string_pt_br, json.bool)
          wisp.json_response(json.to_string(data), 200)
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
        #(category.Fire, fire_enabled),
        #(category.MedicEmergency, emergency_enabled),
        #(category.TrafficAccident, traffic),
        #(category.Other, other),
      ]),
    )
  }

  decode.run(data, schema)
}

fn handle_err(err: UpdateNotificationPreferencesError) -> wisp.Response {
  case err {
    AuthenticationFailed(err) -> user.handle_authentication_error(err)
    DataBaseError(err) -> web.handle_database_error(err)
  }
}

fn update_preferences(
  req: wisp.Request,
  ctx: Context,
  preferences: NotificationPreferences,
) -> Result(List(pog.Returned(Nil)), UpdateNotificationPreferencesError) {
  use user_uuid <- result.try(
    user.extract_uuid(request: req, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AuthenticationFailed),
  )

  use update_result <- result.try({
    use #(key, value) <- list.try_map(dict.to_list(preferences))

    // Parse into the SQL enum
    let key = case key {
      category.Fire -> sql.Fire
      category.MedicEmergency -> sql.Emergency
      category.Other -> sql.Other
      category.TrafficAccident -> sql.Traffic
    }

    sql.update_notification_preferences(ctx.db, user_uuid, key, value)
    |> result.map_error(DataBaseError)
  })

  Ok(update_result)
}

type NotificationPreferences =
  dict.Dict(category.Category, Bool)

type UpdateNotificationPreferencesError {
  AuthenticationFailed(user.AuthenticationError)
  DataBaseError(pog.QueryError)
}
