import app/routes/brigade
import app/routes/login
import app/routes/signup
import app/web.{type Context}
import wisp

/// Handle the incoming requests
pub fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use req <- web.middleware(request: req, context: ctx)

  case wisp.path_segments(req) {
    [] -> wisp.ok()
    ["api", "user", "signup"] -> signup.handle_form_submission(req:, ctx:)
    ["api", "user", "login"] -> login.handle_form_submission(req:, ctx:)

    ["api", "brigade", "get_members", brigade_id] ->
      brigade.get_brigade_members(req:, ctx:, brigade_id:)
    // ["api", "user", "get_fellow_members", user_id] ->
    //   user.get_fellow_members(req:, ctx:, user_id:)
    _ -> wisp.not_found()
  }
}
