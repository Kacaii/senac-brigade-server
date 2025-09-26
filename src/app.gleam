import app/router
import app/web.{Context}
import envoy
import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import gleam/result
import mist
import pog
import wisp
import wisp/wisp_mist

/// Application entry
pub fn main() -> Nil {
  web.configure_logger()

  //   Setup the postgresql database connection -------------------------------
  let db_process_name = process.new_name("db_conn")

  //   Database connection
  let conn = pog.named_connection(db_process_name)

  // Pass the application context to the router
  let ctx = Context(static_directory: static_directory(), conn:)
  let handler = router.handle_request(_, ctx)

  // Secret key used for signing and encryption
  let assert Ok(secret_key) = read_cookie_token()
    as "  Failed to read the cookie secret key"

  // Postgresql connection URI
  let assert Ok(pog_config) = read_connection_uri(db_process_name)
    as "  Failed to read DataBase connection URI"

  // Start both HHTP Server and DataBase connection under a supervision tree ---
  let assert Ok(_) =
    start_application_supervised(pog_config:, handler:, secret_key:)
    as "󰪋  Failed to start the application supervisor"

  // ⏾ 󰒲
  process.sleep_forever()
}

///   Read the `COOKIE_TOKEN` enviroment variable
fn read_cookie_token() -> Result(String, Nil) {
  use cookie_token <- result.try(envoy.get("COOKIE_TOKEN"))
  Ok(cookie_token)
}

/// 󰪋  Start the application supervisor
pub fn start_application_supervised(
  pog_config pog_config: pog.Config,
  handler handler: fn(wisp.Request) -> wisp.Response,
  secret_key secret_key: String,
) -> Result(actor.Started(supervisor.Supervisor), actor.StartError) {
  // Adding Pog to the supervision tree
  let pog_pool_child = pog.supervised(pog_config)

  // Adding Mist to the supervision tree
  let mist_pool_child = {
    wisp_mist.handler(handler, secret_key)
    |> mist.new()
    |> mist.port(8000)
  }

  supervisor.new(supervisor.RestForOne)
  |> supervisor.add(pog_pool_child)
  |> supervisor.add(mist.supervised(mist_pool_child))
  |> supervisor.start
}

///   Read the `DATABASE_URL` environment variable and then
/// build the `pog.Config` from that database URI.
pub fn read_connection_uri(
  name: process.Name(pog.Message),
) -> Result(pog.Config, Nil) {
  // Remember to set the enviroment variable before running the app
  use postgres_url <- result.try(envoy.get("DATABASE_URL"))

  pog.url_config(name, postgres_url)
}

/// Access to static files
pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
    as "Failed to access priv directory"

  priv_directory <> "/static"
}
