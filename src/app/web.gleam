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

import app/web/context
import cors_builder as cors
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/string
import glight
import pog
import wisp

/// Middleware that runs before every request.
/// It sets up the request, and then calls the next handler.
pub fn middleware(
  request req: wisp.Request,
  context ctx: context.Context,
  next handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let path = "/static"
  let request = wisp.method_override(req)

  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes()
  use request <- wisp.handle_head(request)
  use request <- cors.wisp_middleware(request, cors_config())

  use <- wisp.serve_static(request, under: path, from: ctx.static_directory)
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
  |> cors.allow_origin("https://sigo.cbpm.vercel.app")
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
  |> cors.allow_method(http.Put)
  |> cors.allow_method(http.Delete)
  |> cors.allow_header("authorization")
  |> cors.allow_header("content-type")
  |> cors.allow_header("origin")
  |> cors.allow_credentials()
}

pub fn handle_decode_error(
  decode_errors: List(decode.DecodeError),
) -> wisp.Response {
  case list.first(decode_errors) {
    Error(_) -> wisp.ok()
    Ok(err) ->
      json.object([
        #("expected", json.string(err.expected)),
        #("found", json.string(err.found)),
        #("path", json.string(string.join(err.path, "/"))),
      ])
      |> json.to_string
      |> wisp.bad_request()
  }
}

pub fn handle_database_error(err: pog.QueryError) -> wisp.Response {
  case err {
    pog.ConnectionUnavailable ->
      "Conexão com o Banco de Dados não disponível"
      |> wisp.Text
      |> wisp.set_body(wisp.internal_server_error(), _)

    pog.ConstraintViolated(message:, constraint:, detail:) -> {
      json.object([
        #("message", json.string(message)),
        #("constraint", json.string(constraint)),
        #("detail", json.string(detail)),
      ])
      |> json.to_string()
      |> wisp.json_response(500)
    }

    pog.QueryTimeout ->
      "O Banco de Dados demorou muito para responder"
      |> wisp.Text
      |> wisp.set_body(wisp.internal_server_error(), _)

    pog.PostgresqlError(code:, name:, message:) -> {
      json.object([
        #("code", json.string(code)),
        #("name", json.string(name)),
        #("message", json.string(message)),
      ])
      |> json.to_string()
      |> wisp.json_response(500)
    }

    pog.UnexpectedArgumentCount(expected:, got:) -> {
      json.object([
        #("expected", json.int(expected)),
        #("got", json.int(got)),
      ])
      |> json.to_string()
      |> wisp.json_response(500)
    }

    pog.UnexpectedArgumentType(expected:, got:) -> {
      json.object([
        #("expected", json.string(expected)),
        #("got", json.string(got)),
      ])
      |> json.to_string()
      |> wisp.json_response(500)
    }

    pog.UnexpectedResultType(err) -> handle_decode_error(err)
  }
}
