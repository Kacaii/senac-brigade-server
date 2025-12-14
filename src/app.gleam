//// A web application built with the Wisp framework.
////
//// This module is the main entry point for the application. It is responsible for:
//// - Configuring the application's dependencies (database, HTTP server)
//// - Reading necessary environment variables
////
//// ## Architecture
//// The application uses a supervisor to manage two main processes:
//// 1. A PostgreSQL database connection pool using Pog
//// 2. An HTTP server using Mist (with Wisp handling the web layer)

import app/domain/admin/sql as admin_sql
import app/http_router
import app/supervision_tree
import app/web
import app/web/context.{type Context, Context}
import app/web/socket
import envoy
import gleam/bool
import gleam/erlang/process
import gleam/http
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam_community/ansi
import pog
import wisp
import wisp/simulate

/// Application entry
pub fn main() -> Nil {
  web.configure_logger()

  // Enviroment where the code is running on
  let env = case envoy.get("SIGO_PROD") {
    Error(_) -> context.Dev
    Ok(_) -> context.Production
  }

  // NAMES ---------------------------------------------------------------------
  // 󰩵  Setup registry process name
  let registry_name = process.new_name("registry")

  //   Setup the connection process name
  let db_process_name = process.new_name("db_conn")

  // SECRET KEYS ---------------------------------------------------------------
  // Used for signing and encryption
  let assert Ok(secret_key_base) = envoy.get("COOKIE_TOKEN")
    as "  Cookie secret key is available"

  // Postgresql connection URI
  let assert Ok(pog_config) = read_connection_url(db_process_name, env)
    as "  DataBase connection URI is available"

  // Pass the application context to the router
  let ctx =
    Context(
      static_directory: static_directory(),
      db: pog.named_connection(db_process_name),
      registry_name:,
      secret_key_base:,
      env:,
    )

  let wisp_handler = http_router.handle_request(_, ctx)
  let ws_handler = socket.handle_request(_, ctx)

  // Start all essential processes under a supervision tree
  let assert Ok(_) =
    supervision_tree.start(
      ctx:,
      pog_config:,
      wisp_handler:,
      ws_handler:,
      secret_key_base:,
      registry_name:,
    )
    as "󰪋  Start the application supervision tree"

  process.sleep_forever()
}

///   Read the `DATABASE_URL` environment variable and then
/// build the `pog.Config` from that database URI.
///
///   Disables SSL during development
pub fn read_connection_url(
  name: process.Name(pog.Message),
  env: context.Enviroment,
) -> Result(pog.Config, Nil) {
  // Remember to set the enviroment variable before running the app
  use postgres_url <- result.try(envoy.get("DATABASE_URL"))
  use config <- result.map(pog.url_config(name, postgres_url))

  //   Disable SSL when not in production
  case env {
    context.Dev -> config
    context.Production -> pog.ssl(config, pog.SslVerified)
  }
}

/// Access to static files
pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
    as "Erlang's priv directory is generated"

  priv_directory <> "/static"
}

/// Generate a default admin account if the user_account table is empty
pub fn setup_admin(ctx: Context) {
  let assert Ok(returned) = admin_sql.count_total_users(ctx.db)
    as "Check if the users table is empty"
  let assert Ok(row) = list.first(returned.rows)
  use <- bool.guard(when: row.total != 0, return: Nil)

  // Generate a default admin user
  simulate.browser_request(http.Post, "/admin/setup")
  |> simulate.json_body(json.object([#("key", json.string("admin"))]))
  |> http_router.handle_request(request: _, ctx:)

  "Administrador cadastrado com sucesso!"
  |> ansi.green
  |> io.println
}
