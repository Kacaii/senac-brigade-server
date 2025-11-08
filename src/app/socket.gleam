import app/web/context.{type Context}
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/option
import group_registry
import mist

const topic = "default"

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
  registry registry: group_registry.GroupRegistry(context.ServerMessage),
) -> #(Nil, option.Option(process.Selector(context.ServerMessage))) {
  let self = process.self()
  let group_subject = group_registry.join(registry, topic, self)

  let selector =
    process.new_selector()
    |> process.select(group_subject)

  #(Nil, option.Some(selector))
}

fn ws_on_close(
  state _state: Nil,
  ctx _ctx: Context,
  registry registry: group_registry.GroupRegistry(context.ServerMessage),
) -> Nil {
  group_registry.leave(registry, topic, [process.self()])
}

fn ws_handler(
  state state: Nil,
  msg msg: mist.WebsocketMessage(context.ServerMessage),
  ws_conn conn: mist.WebsocketConnection,
  ctx _ctx: Context,
  registry _registry: group_registry.GroupRegistry(context.ServerMessage),
) -> mist.Next(Nil, context.ServerMessage) {
  case msg {
    mist.Text(_) -> mist.continue(state)
    mist.Binary(_) -> mist.continue(state)
    mist.Custom(msg) -> handle_custom_msg(state, msg, conn)
    mist.Closed | mist.Shutdown -> mist.stop()
  }
}

fn handle_custom_msg(
  state: Nil,
  msg: context.ServerMessage,
  conn: mist.WebsocketConnection,
) -> mist.Next(Nil, context.ServerMessage) {
  case msg {
    context.Broadcast(message) -> {
      let msg_result = mist.send_text_frame(conn, message)
      case msg_result {
        Error(_) -> mist.stop_abnormal("Failed to broadcast message")
        Ok(_) -> mist.continue(state)
      }
    }
    context.Ping -> {
      let msg_result = mist.send_text_frame(conn, "  Pong")
      case msg_result {
        Error(_) -> mist.stop_abnormal("Failed to reply with pong")
        Ok(_) -> mist.continue(state)
      }
    }
  }
}
