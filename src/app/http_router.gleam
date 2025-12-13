//// Application router that maps HTTP requests to handler functions.
////
//// This module defines the URL routing table for the application's API endpoints.
//// It uses path-based routing to delegate requests to specific handler modules
//// for processing.
////
//// All requests are processed through the web middleware pipeline before routing.
//// Unmatched routes return a 404 Not Found response.

import app/domain/admin/admin_update_user
import app/domain/admin/setup_first_admin
import app/domain/brigade/delete_brigade
import app/domain/brigade/get_all_brigades
import app/domain/brigade/get_brigade_members
import app/domain/brigade/register_new_brigade
import app/domain/brigade/update_brigade_status
import app/domain/dashboard
import app/domain/data_analysis/analysis_occurrence_volume
import app/domain/notification/get_notification_preferences
import app/domain/notification/update_notification_preferences
import app/domain/occurrence/delete_occurrence
import app/domain/occurrence/get_ocurrences_by_applicant
import app/domain/occurrence/register_new_occurrence
import app/domain/occurrence/update_occurrence_status
import app/domain/role/get_role_list
import app/domain/user/delete_user
import app/domain/user/get_all_user_profiles
import app/domain/user/get_crew_members
import app/domain/user/get_user_profile
import app/domain/user/login
import app/domain/user/signup
import app/domain/user/update_user_password
import app/domain/user/update_user_profile
import app/domain/user/update_user_status
import app/web
import app/web/context.{type Context}
import gleam/http
import wisp

/// 󱂇  Main request router - matches HTTP methods and paths to appropriate handlers
/// All routes pass through middleware first for common processing
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use request <- web.middleware(request:, context: ctx)
  case request.method, wisp.path_segments(request) {
    //   Security routes -------------------------------------------------
    http.Post, ["user", "login"] -> login.handle_request(request:, ctx:)

    http.Put, ["user", "password"] ->
      update_user_password.handle_request(request:, ctx:)

    //   Admin routes ---------------------------------------------------------
    http.Post, ["admin", "setup"] ->
      setup_first_admin.handle_request(request:, ctx:)

    http.Post, ["admin", "signup"] -> signup.handle_request(request:, ctx:)

    http.Get, ["admin", "users"] ->
      get_all_user_profiles.handle_request(request:, ctx:)

    http.Put, ["admin", "users", id] ->
      admin_update_user.handle_request(request:, ctx:, id:)

    http.Delete, ["admin", "users", id] ->
      delete_user.handle_request(request:, ctx:, id:)

    http.Put, ["admin", "users", id, "status"] ->
      update_user_status.handle_request(request:, ctx:, id:)

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

    // 󰕮  Data analysis routes
    http.Get, ["analysis", "occurrence"] ->
      analysis_occurrence_volume.handle_request(request:, ctx:)

    //   User data routes -----------------------------------------------------
    http.Get, ["user", id, "occurrences"] ->
      get_ocurrences_by_applicant.handle_request(request:, ctx:, id:)

    http.Get, ["user", "profile"] ->
      get_user_profile.handle_request(request:, ctx:)

    http.Put, ["user", "profile"] ->
      update_user_profile.handle_request(request:, ctx:)

    http.Get, ["user", id, "crew_members"] ->
      get_crew_members.handle_request(request:, ctx:, id:)

    //   Notification routes --------------------------------------------------
    http.Get, ["user", "notification_preferences"] ->
      get_notification_preferences.handle_request(request:, ctx:)

    http.Put, ["user", "notification_preferences"] ->
      update_notification_preferences.handle_request(request:, ctx:)

    // 󰞏  Occurrence routes ----------------------------------------------------
    http.Post, ["occurrence", "new"] ->
      register_new_occurrence.handle_request(request:, ctx:)

    http.Delete, ["occurrence", id] ->
      delete_occurrence.handle_request(request:, ctx:, id:)

    http.Post, ["occurrence", "resolved_at", id]
    | http.Delete, ["occurrence", "resolved_at", id]
    -> update_occurrence_status.handle_request(request:, ctx:, id:)

    // 󰢫  Brigade routes -------------------------------------------------------
    http.Get, ["brigade", id, "members"] ->
      get_brigade_members.handle_request(request:, ctx:, id:)

    //   Role routes ----------------------------------------------------------
    http.Get, ["user", "roles"] -> get_role_list.handle_request(request:, ctx:)

    // Fallback routes ---------------------------------------------------------
    _, [] -> wisp.ok() |> wisp.html_body("<h2>🌠</h2>")
    _, _ -> wisp.not_found()
  }
}
