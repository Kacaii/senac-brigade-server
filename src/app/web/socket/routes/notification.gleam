import app/routes/occurrence/category
import app/web/context.{type Context}
import app/web/socket/envelope
import app/web/socket/routes/notification/message as msg
import gleam/bool
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/time/timestamp
import group_registry
import mist
import youid/uuid

pub const topic = "occurrence_notifications"

pub opaque type State {
  State(user_uuid: uuid.Uuid, subscribed: List(category.Category))
}

pub fn handle_connection(
  req: request.Request(mist.Connection),
  ctx: Context,
  user_uuid: uuid.Uuid,
) -> response.Response(mist.ResponseData) {
  let registry = group_registry.get_registry(ctx.notification_registry_name)
  mist.websocket(
    request: req,
    on_init: ws_on_init(_, req, ctx, user_uuid, registry),
    on_close: ws_on_close(_, ctx, registry),
    handler: fn(state, msg, conn) {
      ws_handler(state, msg, conn, ctx, registry)
    },
  )
}

fn ws_handler(
  state state: State,
  msg msg: mist.WebsocketMessage(msg.Msg),
  conn conn: mist.WebsocketConnection,
  ctx _ctx: Context,
  registry _registry: group_registry.GroupRegistry(msg.Msg),
) -> mist.Next(State, msg.Msg) {
  case msg {
    mist.Text(_) -> mist.continue(state)
    mist.Binary(_) -> mist.continue(state)
    mist.Closed | mist.Shutdown -> mist.stop()
    mist.Custom(msg) -> handle_custom_msg(state, msg, conn)
  }
}

fn handle_custom_msg(
  state: State,
  msg: msg.Msg,
  conn: mist.WebsocketConnection,
) -> mist.Next(State, msg.Msg) {
  case msg {
    msg.NewOccurrence(occ_id:, occ_type:) -> {
      // Do nothing if the user is not subscribed
      use <- bool.guard(
        when: list.any(state.subscribed, fn(maybe) { maybe == occ_type }),
        return: mist.continue(state),
      )

      // Send notification
      send_envelope(
        state:,
        conn:,
        data_type: "new_occurrence",
        data: json.object([
          #("id", uuid.to_string(occ_id) |> json.string),
          #("type", category.to_string(occ_type) |> json.string),
        ]),
      )
    }
  }
}

pub fn send_envelope(
  state state: State,
  conn conn: mist.WebsocketConnection,
  data_type data_type: String,
  data data: json.Json,
) -> mist.Next(State, msg.Msg) {
  //   Build metadata
  let meta =
    envelope.MetaData(
      timestamp: timestamp.system_time(),
      request_id: state.user_uuid,
    )

  // 󰛮  Wrap envelope
  let envelope_json =
    envelope.to_json(envelope.Envelope(data_type:, data:, meta:))

  // 󱅡  Send data
  let msg_result = mist.send_text_frame(conn, json.to_string(envelope_json))
  case msg_result {
    Error(_) -> mist.stop_abnormal("Failed to send envelope to User")
    Ok(_) -> mist.continue(state)
  }
}

fn ws_on_close(
  state _state: State,
  ctx _ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.Msg),
) -> Nil {
  group_registry.leave(registry, topic, [process.self()])
}

fn ws_on_init(
  conn _conn: mist.WebsocketConnection,
  req req: request.Request(mist.Connection),
  ctx _ctx: Context,
  user_uuid user_uuid: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(msg.Msg),
) -> #(State, option.Option(process.Selector(msg.Msg))) {
  let query = result.unwrap(request.get_query(req), [])
  let state =
    list.fold(query, State(user_uuid:, subscribed: []), fn(acc, query) {
      case query {
        #("occurrences", "fire") ->
          State(..acc, subscribed: [category.Fire, ..acc.subscribed])
        #("occurrences", "emergency") ->
          State(..acc, subscribed: [category.MedicEmergency, ..acc.subscribed])
        #("occurrences", "traffic") ->
          State(..acc, subscribed: [category.TrafficAccident, ..acc.subscribed])
        #("occurrences", "other") ->
          State(..acc, subscribed: [category.Other, ..acc.subscribed])
        #(_, _) -> acc
      }
    })

  let self = process.self()
  let group_subject = group_registry.join(registry, topic, self)

  let selector =
    process.new_selector()
    |> process.select(group_subject)

  #(state, option.Some(selector))
}
