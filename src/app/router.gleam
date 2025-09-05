import app/web.{type Context}
import wisp

pub fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use req <- web.middleware(request: req, context: ctx)

  case wisp.path_segments(req) {
    [] -> wisp.ok()
    _ -> wisp.not_found()
  }
}
