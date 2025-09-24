import app/routes/get_brigade_members
import app/routes/get_fellow_brigade_members
import app/routes/login
import app/routes/signup
import app/web.{type Context}
import wisp

/// Handle the incoming requests
pub fn handle_request(request: wisp.Request, ctx: Context) -> wisp.Response {
  use request <- web.middleware(request: request, context: ctx)

  case wisp.path_segments(request) {
    [] -> wisp.ok()
    ["api", "user", "signup"] -> signup.handle_form_submission(request:, ctx:)
    ["api", "user", "login"] -> login.handle_form_submission(request:, ctx:)

    ["api", "brigade", "get_members", brigade_id] ->
      get_brigade_members.handle_request(request:, ctx:, brigade_id:)
    ["api", "user", "get_fellow_members", user_id] ->
      get_fellow_brigade_members.handle_request(request:, ctx:, user_id:)

    _ -> wisp.not_found()
  }
}
