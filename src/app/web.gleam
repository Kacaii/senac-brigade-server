//// Web application context and middleware configuration.
////
//// This module defines the core web infrastructure including:
//// - The `Context` type that holds application dependencies for request handlers
//// - Middleware pipeline for request processing
//// - CORS configuration for cross-origin requests
//// - Logger configuration for application logging
////
//// ## Middleware Pipeline
//// The middleware function applies the following processing to each request:
//// - HTTP method overriding (for REST clients)
//// - Request logging
//// - Crash recovery and error handling
//// - HEAD request normalization
//// - CORS headers
//// - Static file serving from `/static` path

import cors_builder as cors
import gleam/http
import glight
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

///   Configure the Erlang logger
pub fn configure_logger() {
  glight.configure([
    glight.Console,
    glight.File(log_directory() <> "/server.log"),
  ])

  glight.set_log_level(glight.Debug)
  glight.set_is_color(True)
}

/// Access to log directory
fn log_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
    as "Failed to access priv directory"

  priv_directory <> "/log"
}

fn cors_config() -> cors.Cors {
  cors.new()
  |> cors.allow_origin("http://localhost:5173")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
  |> cors.allow_method(http.Put)
  |> cors.allow_method(http.Delete)
  |> cors.allow_header("authorization")
  |> cors.allow_header("content-type")
  |> cors.allow_header("origin")
  |> cors.allow_credentials()
}
