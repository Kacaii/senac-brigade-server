//// Application router that maps HTTP requests to handler functions.
////
//// This module defines the URL routing table for the application's API endpoints.
//// It uses path-based routing to delegate requests to specific handler modules
//// for processing.
////
//// All requests are processed through the web middleware pipeline before routing.
//// Unmatched routes return a 404 Not Found response.

import app/routes/brigade/delete_brigade
import app/routes/brigade/get_all_brigades
import app/routes/brigade/get_brigade_members
import app/routes/brigade/register_new_brigade
import app/routes/brigade/update_brigade_status
import app/routes/dashboard
import app/routes/notification/get_notification_preferences
import app/routes/notification/update_notification_preferences
import app/routes/occurrence/register_new_occurrence
import app/routes/role/get_role_list
import app/routes/user/get_crew_members
import app/routes/user/get_ocurrences_by_applicant
import app/routes/user/get_user_profile
import app/routes/user/login
import app/routes/user/signup
import app/routes/user/update_user_password
import app/web.{type Context}
import gleam/http
import wisp

/// Handle the incoming HTTP Requests
pub fn handle_request(request: wisp.Request, ctx: Context) -> wisp.Response {
  use request <- web.middleware(request: request, context: ctx)

  case request.method, wisp.path_segments(request) {
    //   Security routes -------------------------------------------------
    http.Post, ["user", "login"] -> login.handle_request(request:, ctx:)
    http.Put, ["user", "password"] ->
      update_user_password.handle_request(request:, ctx:)

    //   Admin routes ---------------------------------------------------------
    http.Post, ["admin", "signup"] -> signup.handle_request(request:, ctx:)
    http.Get, ["admin", "teams"] ->
      get_all_brigades.handle_request(request:, ctx:)
    http.Post, ["admin", "teams"] ->
      register_new_brigade.handle_request(request:, ctx:)
    http.Put, ["admin", "teams", id, "status"] ->
      update_brigade_status.handle_request(request:, ctx:, id:)
    http.Delete, ["admin", "teams", id] ->
      delete_brigade.handle_request(request:, ctx:, id:)

    // 󰨇  Dashboard stats ------------------------------------------------------
    http.Get, ["dashboard", "stats"] -> dashboard.handle_request(request:, ctx:)

    //   User data routes -----------------------------------------------------
    http.Get, ["user", id, "occurrences"] ->
      get_ocurrences_by_applicant.handle_request(request:, ctx:, id:)

    http.Get, ["user", "profile"] ->
      get_user_profile.handle_request(request:, ctx:)

    http.Get, ["user", id, "crew_members"] ->
      get_crew_members.handle_request(request:, ctx:, id:)

    //   Notification routes --------------------------------------------------
    http.Get, ["user", "notification_preferences"] ->
      get_notification_preferences.handle_request(request, ctx)

    http.Put, ["user", "notification_preferences"] ->
      update_notification_preferences.handle_request(request, ctx)

    // 󰞏  Occurrence routes ----------------------------------------------------
    http.Post, ["occurrence", "new"] ->
      register_new_occurrence.handle_request(request:, ctx:)

    // 󰢫  Brigade routes -------------------------------------------------------
    http.Get, ["brigade", id, "members"] ->
      get_brigade_members.handle_request(request:, ctx:, id:)

    //   Role routes ----------------------------------------------------------
    http.Get, ["user", "roles"] -> get_role_list.handle_request(request, ctx)

    // Fallback routes ---------------------------------------------------------
    _, [] -> wisp.ok()
    _, _ -> wisp.not_found()
  }
}
