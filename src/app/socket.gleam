import app/web/context.{type Context}
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/option
import group_registry
import mist

const ws_group_name = "ws_group"

/// 󱘖  Stabilishes a websocket connection with the client
pub fn handle_request(
  req: request.Request(mist.Connection),
  ctx: Context,
) -> response.Response(mist.ResponseData) {
  let registry = group_registry.get_registry(ctx.registry_name)

  mist.websocket(
    request: req,
    on_init: ws_on_init(_, ctx, registry),
    on_close: ws_on_close(_, ctx, registry),
    handler: fn(state, msg, conn) {
      ws_handler(state, msg, conn, ctx, registry)
    },
  )
}

fn ws_on_init(
  conn _conn: mist.WebsocketConnection,
  ctx _ctx: Context,
  registry registry: group_registry.GroupRegistry(Nil),
) -> #(Nil, option.Option(process.Selector(Nil))) {
  let self = process.self()
  let group_subject = group_registry.join(registry, ws_group_name, self)

  let selector =
    process.new_selector()
    |> process.select(group_subject)

  #(Nil, option.Some(selector))
}

fn ws_on_close(
  state _state: Nil,
  ctx _ctx: Context,
  registry registry: group_registry.GroupRegistry(Nil),
) -> Nil {
  group_registry.leave(registry, ws_group_name, [process.self()])
}

fn ws_handler(
  state state: Nil,
  msg msg: mist.WebsocketMessage(Nil),
  ws_conn _ws_conn: mist.WebsocketConnection,
  ctx _ctx: Context,
  registry _registry: group_registry.GroupRegistry(Nil),
) -> mist.Next(Nil, Nil) {
  case msg {
    mist.Text(_) -> mist.continue(state)
    mist.Binary(_) -> mist.continue(state)
    mist.Custom(_) -> mist.continue(state)
    mist.Closed | mist.Shutdown -> mist.stop()
  }
}
