import app/router
import app/web.{Context}
import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import mist
import pog
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let db_process_name = process.new_name("db_conn")
  let assert Ok(pog_config) = read_connection_uri(db_process_name)
  echo pog_config
  let assert Ok(_) = start_application_supervised(pog_config)

  // Database connection
  let conn = pog.named_connection(db_process_name)

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

pub fn start_application_supervised(
  pog_config: pog.Config,
) -> Result(actor.Started(supervisor.Supervisor), actor.StartError) {
  let pool_child = pog.supervised(pog_config)

  supervisor.new(supervisor.RestForOne)
  |> supervisor.add(pool_child)
  |> supervisor.start
}

/// Read the DATABASE_URL environment variable and then
/// build the pog.Config from that database URL.
pub fn read_connection_uri(
  name: process.Name(pog.Message),
) -> Result(pog.Config, Nil) {
  use postgres_url <- todo as "Connect to  Database"
  pog.url_config(name, postgres_url)
}

/// Access to Erlang's Priv directory
pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
  priv_directory <> "/static"
}
