import app/handler/signup
import app/web.{type Context}
import wisp

/// Handle the incoming requests
pub fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use req <- web.middleware(request: req, context: ctx)

  case wisp.path_segments(req) {
    [] -> wisp.ok()
    ["cadastrar"] -> signup.handle_form_submission(req, ctx)
    _ -> wisp.not_found()
  }
}
