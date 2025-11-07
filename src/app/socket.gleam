import app/web.{type Context}
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/option
import mist

/// 󱘖  Stabilishes a websocket connection to the client, allowing the server
/// to send data to them
pub fn handle_request(
  req: request.Request(mist.Connection),
  ctx: Context,
) -> response.Response(mist.ResponseData) {
  mist.websocket(
    request: req,
    handler: ws_handler,
    on_init: ws_on_init(_, ctx),
    on_close: ws_on_close(_, ctx),
  )
}

fn ws_on_init(
  _conn: mist.WebsocketConnection,
  state: Context,
) -> #(Context, option.Option(process.Selector(msg))) {
  #(state, option.None)
}

fn ws_on_close(_state, _ctx) -> Nil {
  Nil
}

fn ws_handler(
  state: web.Context,
  msg: mist.WebsocketMessage(msg),
  _ws_conn: mist.WebsocketConnection,
) -> mist.Next(Context, msg) {
  case msg {
    mist.Text(_) -> mist.continue(state)
    mist.Binary(_) -> mist.continue(state)
    mist.Custom(_) -> mist.continue(state)
    mist.Closed | mist.Shutdown -> mist.stop()
  }
}
