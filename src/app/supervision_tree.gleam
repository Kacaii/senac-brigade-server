import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import group_registry
import mist
import pog
import wisp
import wisp/wisp_mist

/// 󰪋  Start the application supervisor
pub fn start(
  pog_config pog_config: pog.Config,
  wisp_handler wisp_handler: fn(wisp.Request) -> wisp.Response,
  ws_handler ws_handler: fn(request.Request(mist.Connection)) ->
    response.Response(mist.ResponseData),
  secret_key_base secret_key_base: String,
  registry_name registry_name: process.Name(_),
) -> Result(actor.Started(supervisor.Supervisor), actor.StartError) {
  // Handler for the web server
  let webserver_handler = fn(req) {
    case wisp.path_segments(req) {
      ["ws"] | ["ws", _] -> ws_handler(req)
      _ -> wisp_mist.handler(wisp_handler, secret_key_base)(req)
    }
  }

  // Adding Mist to the supervision tree
  let mist_pool_child =
    webserver_handler
    |> mist.new
    |> mist.port(8000)

  // Starting supervision
  supervisor.new(supervisor.OneForOne)
  |> supervisor.add(pog.supervised(pog_config))
  |> supervisor.add(mist.supervised(mist_pool_child))
  |> supervisor.add(group_registry.supervised(registry_name))
  |> supervisor.start
}
