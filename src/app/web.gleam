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
  let request = wisp.method_override(req)
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes()
  use request <- wisp.handle_head(request)
  use request <- cors.wisp_middleware(request, cors_config())
  use <- wisp.serve_static(
    request,
    under: "/static",
    from: ctx.static_directory,
  )

  handle_request(request)
}

fn cors_config() -> cors.Cors {
  cors.new()
  |> cors.allow_origin("http://localhost:5173")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}
