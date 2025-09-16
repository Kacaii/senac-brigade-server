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
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  //   Setup the postgres database connection ---------------------------------
  let db_process_name = process.new_name("db_conn")

  let assert Ok(pog_config) = read_connection_uri(db_process_name)
    as "Failed to read connection URI"
  let assert Ok(_) = start_application_supervised(pog_config)
    as "Failed to database supervisor"

  //   Database connection
  let conn = pog.named_connection(db_process_name)

  // Pass the application context to the router
  let ctx = Context(static_directory: static_directory(), conn:)
  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new()
    |> mist.port(8000)
    |> mist.start

  // ⏾ 󰒲
  process.sleep_forever()
}

///   Start the postgres application supervisor
pub fn start_application_supervised(
  pog_config: pog.Config,
) -> Result(actor.Started(supervisor.Supervisor), actor.StartError) {
  let pool_child = pog.supervised(pog_config)

  supervisor.new(supervisor.RestForOne)
  |> supervisor.add(pool_child)
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

/// Access to Erlang's Priv directory
pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
    as "Failed to access priv directory"

  priv_directory <> "/static"
}
