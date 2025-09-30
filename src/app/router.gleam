//// Application router that maps HTTP requests to handler functions.
////
//// This module defines the URL routing table for the application's API endpoints.
//// It uses path-based routing to delegate requests to specific handler modules
//// for processing.
////
//// All requests are processed through the web middleware pipeline before routing.
//// Unmatched routes return a 404 Not Found response.

import app/routes/get_brigade_members
import app/routes/get_crew_members
import app/routes/get_ocurrences_by_applicant
import app/routes/login
import app/routes/register_new_occurrence
import app/routes/signup
import app/web.{type Context}
import gleam/http
import wisp

/// Handle the incoming HTTP Requests
pub fn handle_request(request: wisp.Request, ctx: Context) -> wisp.Response {
  use request <- web.middleware(request: request, context: ctx)

  case request.method, wisp.path_segments(request) {
    //   Authorization routes
    http.Post, ["api", "user", "signup"] -> signup.handle_form(request:, ctx:)
    http.Post, ["api", "user", "login"] -> login.handle_form(request:, ctx:)

    //   User data routes
    http.Get, ["api", "user", id, "occurrences"] ->
      get_ocurrences_by_applicant.handle_request(request:, ctx:, id:)
    http.Get, ["api", "user", id, "crew_members"] ->
      get_crew_members.handle_request(request:, ctx:, id:)

    // 󰞏  Occurrence routes
    http.Post, ["api", "occurence", "new"] ->
      register_new_occurrence.handle_form(request:, ctx:)

    // 󰢫  Brigade routes
    http.Get, ["api", "brigade", id, "members"] ->
      get_brigade_members.handle_request(request:, ctx:, id:)

    // Fallback routes
    _, [] -> wisp.ok()
    _, _ -> wisp.not_found()
  }
}
