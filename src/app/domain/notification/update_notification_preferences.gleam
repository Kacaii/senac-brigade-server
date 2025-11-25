import app/domain/notification/sql
import app/domain/occurrence/category
import app/domain/user
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

  case decode.run(json_data, body_decoder()) {
    Error(err) -> web.handle_decode_error(err)
    Ok(data) -> handle_data(req, ctx, data)
  }
}

type UpdateNotificationPreferencesError {
  /// Authentication failed
  AccessControl(user.AuthenticationError)
  /// Failed to query Database
  DataBase(pog.QueryError)
  NotFound
}

fn handle_data(
  req: wisp.Request,
  ctx: Context,
  data: dict.Dict(category.Category, Bool),
) -> wisp.Response {
  case try_update_preferences(req, ctx, data) {
    Error(err) -> handle_error(err)
    Ok(updated_values) ->
      json.dict(updated_values, category.to_string_pt_br, json.bool)
      |> json.to_string
      |> wisp.json_response(200)
  }
}

fn body_decoder() -> decode.Decoder(dict.Dict(category.Category, Bool)) {
  use fire_enabled <- decode.field("incendio", decode.bool)
  use emergency_enabled <- decode.field("emergencia", decode.bool)
  use traffic <- decode.field("transito", decode.bool)
  use other <- decode.field("outros", decode.bool)

  [
    #(category.Fire, fire_enabled),
    #(category.MedicEmergency, emergency_enabled),
    #(category.TrafficAccident, traffic),
    #(category.Other, other),
  ]
  |> dict.from_list
  |> decode.success
}

fn handle_error(err: UpdateNotificationPreferencesError) -> wisp.Response {
  case err {
    AccessControl(err) -> user.handle_authentication_error(err)
    DataBase(err) -> web.handle_database_error(err)
    NotFound ->
      "O banco de dados não retornou resultados após atualizar as preferências"
      |> wisp.Text
      |> wisp.set_body(wisp.not_found(), _)
  }
}

fn try_update_preferences(
  req: wisp.Request,
  ctx: Context,
  preferences: dict.Dict(category.Category, Bool),
) -> Result(
  dict.Dict(category.Category, Bool),
  UpdateNotificationPreferencesError,
) {
  use user_uuid <- result.try(
    user.extract_uuid(request: req, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AccessControl),
  )

  use acc, #(key, value) <- list.try_fold(
    over: dict.to_list(preferences),
    from: dict.new(),
  )

  let key = case key {
    category.Fire -> sql.Fire
    category.MedicEmergency -> sql.Emergency
    category.Other -> sql.Other
    category.TrafficAccident -> sql.Traffic
  }

  use returned <- result.try(
    sql.update_notification_preferences(ctx.db, user_uuid, key, value)
    |> result.map_error(DataBase),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(NotFound),
  )

  let new_key = case row.notification_type {
    sql.Emergency -> category.MedicEmergency
    sql.Fire -> category.Fire
    sql.Other -> category.Other
    sql.Traffic -> category.TrafficAccident
  }

  dict.insert(acc, new_key, row.enabled)
}
