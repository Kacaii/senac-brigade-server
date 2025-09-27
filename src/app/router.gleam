//// Application router that maps HTTP requests to handler functions.
////
//// This module defines the URL routing table for the application's API endpoints.
//// It uses path-based routing to delegate requests to specific handler modules
//// for processing.
////
//// ## API Endpoints
////
//// ### POST Endpoints
//// - `POST /api/user/signup` - User registration
//// - `POST /api/user/login` - User authentication
//// - `POST /api/occurence/new` - Create a new occurrence
////
//// ### GET Endpoints
//// - `GET /api/user/get_occurences/{user_id}` - Get occurrences by applicant
//// - `GET /api/user/get_fellow_members/{user_id}` - Get fellow brigade members
//// - `GET /api/brigade/get_members/{brigade_id}` - Get members of a specific brigade
////
//// All requests are processed through the web middleware pipeline before routing.
//// Unmatched routes return a 404 Not Found response.

import app/routes/get_brigade_members
import app/routes/get_fellow_brigade_members
import app/routes/get_ocurrences_by_applicant
import app/routes/login
import app/routes/register_new_occurrence
import app/routes/signup
import app/web.{type Context}
import wisp

/// Handle the incoming HTTP Requests
pub fn handle_request(request: wisp.Request, ctx: Context) -> wisp.Response {
  use request <- web.middleware(request: request, context: ctx)

  case wisp.path_segments(request) {
    // POST --------------------------------------------------------------------
    ["api", "user", "signup"] -> signup.handle_form_submission(request:, ctx:)
    ["api", "user", "login"] -> login.handle_form_submission(request:, ctx:)
    ["api", "occurence", "new"] ->
      register_new_occurrence.handle_form_submission(request:, ctx:)

    // GET ---------------------------------------------------------------------
    ["api", "user", "get_occurences", user_id] ->
      get_ocurrences_by_applicant.handle_request(request:, ctx:, user_id:)
    ["api", "user", "get_fellow_members", user_id] ->
      get_fellow_brigade_members.handle_request(request:, ctx:, user_id:)
    ["api", "brigade", "get_members", brigade_id] ->
      get_brigade_members.handle_request(request:, ctx:, brigade_id:)

    // OTHERS ------------------------------------------------------------------
    [] -> wisp.ok()
    _ -> wisp.not_found()
  }
}
