import app/domain/notification/sql
import app/domain/occurrence/category
import app/domain/user
import app/web
import app/web/context.{type Context}
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
    Ok(body) -> wisp.json_response(body, 200)
  }
}

fn handle_error(err: GetNotificationPreferencesError) -> wisp.Response {
  case err {
    AccessControl(err) -> user.handle_authentication_error(err)
    DatabaseError(err) -> web.handle_database_error(err)
  }
}

fn query_database(
  req: wisp.Request,
  ctx: Context,
) -> Result(String, GetNotificationPreferencesError) {
  use user_uuid <- result.try(
    user.extract_uuid(request: req, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AccessControl),
  )

  use returned <- result.try(
    sql.query_notification_preferences(ctx.db, user_uuid)
    |> result.map_error(DatabaseError),
  )

  let preferences = {
    use acc, row <- list.fold(returned.rows, dict.new())
    let occ_category = case row.notification_type {
      sql.Emergency -> category.MedicEmergency
      sql.Fire -> category.Fire
      sql.Other -> category.Other
      sql.Traffic -> category.TrafficAccident
    }

    dict.insert(acc, occ_category, row.enabled)
  }

  json.dict(preferences, category.to_string, json.bool)
  |> json.to_string
  |> Ok
}

/// Querying the user notification preferences can fail
type GetNotificationPreferencesError {
  /// Authentication failed
  AccessControl(user.AuthenticationError)
  /// An error occurred while querying the DataBase
  DatabaseError(pog.QueryError)
}
