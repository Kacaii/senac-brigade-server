import app/web.{type Context, Context}
import wisp

pub fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> todo as "handle '/'"
    _ -> wisp.not_found()
  }
}
