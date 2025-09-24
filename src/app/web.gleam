import cors_builder as cors
import gleam/http
import pog
import wisp

/// Holds any additional data that the request handlers need in addition to the request:
/// Like API Keys, configurations,  database connections, and others
pub type Context {
  Context(static_directory: String, conn: pog.Connection)
}

/// Middleware that runs before every request.
/// It sets up the request, and then calls the next handler.
pub fn middleware(
  request req: wisp.Request,
  context ctx: Context,
  next handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes()
  use req <- wisp.handle_head(req)
  use req <- cors.wisp_middleware(req, cors_config())
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}

fn cors_config() -> cors.Cors {
  cors.new()
  |> cors.allow_origin("http://localhost:5173")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}
