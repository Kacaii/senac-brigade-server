import app/routes/occurrence/category
import app/routes/user
import app/web/context.{type Context}
import app/web/socket/envelope
import app/web/socket/message as msg
import gleam/bit_array
import gleam/bool
import gleam/bytes_tree
import gleam/crypto
import gleam/dynamic/decode
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

pub const topic = "active_users"

/// Connecting to a websocket can fail
pub opaque type WebSocketError {
  /// Session cookie was not found
  MissingCookie
  /// `crypto.verify_signed_message` failed
  InvalidSignature
  /// The signed message could not be properly decrypted
  InvalidUtf8
  /// Decrypted string was not a valid Uuid
  InvalidUuid(String)
}

/// 󱘖  Stabilishes a websocket connection with the client
pub fn handle_request(
  req: request.Request(mist.Connection),
  ctx: Context,
) -> response.Response(mist.ResponseData) {
  let registry = group_registry.get_registry(ctx.registry_name)
  let maybe_uuid = extract_uuid_mist(req, ctx)

  case maybe_uuid {
    Error(err) -> handle_ws_error(err)
    Ok(user_uuid) -> handle_connection(req, ctx, user_uuid, registry)
  }
}

///   Current state of the websocket connection
pub opaque type State {
  State(
    ///   User connected to this socket
    user_uuid: uuid.Uuid,
    /// 󱥁  Notifications that the user wants to receive
    subscribed_categories: List(category.Category),
  )
}

fn handle_connection(
  req: request.Request(mist.Connection),
  ctx: Context,
  user_uuid: uuid.Uuid,
  registry: group_registry.GroupRegistry(msg.Msg),
) -> response.Response(mist.ResponseData) {
  let handler =
    mist.websocket(
      request: req,
      on_init: ws_on_init(_, req, ctx, user_uuid, registry),
      on_close: ws_on_close(_, ctx, registry),
      handler: fn(state, msg, conn) {
        ws_handler(state, msg, conn, ctx, registry)
      },
    )

  case request.path_segments(req) {
    ["ws"] -> handler
    _ -> build_error_response("Not found", 404)
  }
}

fn ws_handler(
  state state: State,
  msg msg: mist.WebsocketMessage(msg.Msg),
  ws_conn ws_conn: mist.WebsocketConnection,
  ctx ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.Msg),
) -> mist.Next(State, msg.Msg) {
  case msg {
    mist.Text(_) -> mist.continue(state)
    mist.Binary(_) -> mist.continue(state)
    mist.Custom(msg) -> handle_custom_msg(state, msg, ws_conn, ctx, registry)
    mist.Closed | mist.Shutdown -> mist.stop()
  }
}

fn handle_custom_msg(
  state: State,
  msg: msg.Msg,
  conn: mist.WebsocketConnection,
  _ctx: Context,
  _registry: group_registry.GroupRegistry(msg.Msg),
) -> mist.Next(State, msg.Msg) {
  case msg {
    msg.Ping ->
      send_envelope(
        state:,
        conn:,
        data_type: "ping",
        data: json.object([#("message", "  Pong" |> json.string)]),
      )

    msg.Broadcast(body) -> {
      use <- bool.guard(when: body == "", return: mist.continue(state))
      send_envelope(
        state:,
        conn:,
        data_type: "broadcast",
        data: json.object([#("message", body |> json.string)]),
      )
    }

    msg.UserAssignedToBrigade(user_id:, brigade_id:) ->
      send_envelope(
        state:,
        conn:,
        data_type: "assigned_to_brigade",
        data: json.object([
          #("user_id", uuid.to_string(user_id) |> json.string),
          #("brigade_id", uuid.to_string(brigade_id) |> json.string),
        ]),
      )

    msg.UserAssignedToOccurrence(user_id:, occurrence_id:) ->
      send_envelope(
        state:,
        conn:,
        data_type: "assigned_to_occurrence",
        data: json.object([
          #("user_id", uuid.to_string(user_id) |> json.string),
          #("occurrence_id", uuid.to_string(occurrence_id) |> json.string),
        ]),
      )

    msg.NewOccurrence(occ_id:, occ_type:) ->
      case
        list.any(state.subscribed_categories, fn(item) { item == occ_type })
      {
        False -> mist.continue(state)
        True ->
          send_envelope(
            state:,
            conn:,
            data_type: "new_occurrence",
            data: json.object([
              #("id", json.string(uuid.to_string(occ_id))),
              #("occ_type", json.string(category.to_string_pt_br(occ_type))),
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

pub fn extract_uuid_mist(
  req: request.Request(mist.Connection),
  ctx: Context,
) -> Result(uuid.Uuid, WebSocketError) {
  let cookies = request.get_cookies(req)
  let salt = <<ctx.secret_key_base:utf8>>

  use hashed_uuid <- result.try(
    list.key_find(cookies, user.uuid_cookie_name)
    |> result.replace_error(MissingCookie),
  )

  use decrypted <- result.try(
    crypto.verify_signed_message(hashed_uuid, salt)
    |> result.replace_error(InvalidSignature),
  )

  use maybe_uuid_str <- result.try(
    bit_array.to_string(decrypted)
    |> result.replace_error(InvalidUtf8),
  )

  use user_uuid <- result.try(
    uuid.from_string(maybe_uuid_str)
    |> result.replace_error(InvalidUuid(maybe_uuid_str)),
  )

  Ok(user_uuid)
}

// ON INIT ---------------------------------------------------------------------

fn ws_on_init(
  conn _conn: mist.WebsocketConnection,
  req req: request.Request(mist.Connection),
  ctx _ctx: Context,
  user_uuid user_uuid: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(msg.Msg),
) -> #(State, option.Option(process.Selector(msg.Msg))) {
  let self = process.self()
  let group_subject = group_registry.join(registry, topic, self)

  let user_subject =
    group_registry.join(registry, uuid.to_string(user_uuid), self)

  let selector =
    process.new_selector()
    |> process.select(group_subject)
    |> process.select(user_subject)

  let body = {
    use req <- result.try(
      mist.read_body(req, 1024 * 1024 * 10)
      |> result.replace_error(Nil),
    )
    use body <- result.map(
      bit_array.to_string(req.body)
      |> result.replace_error(Nil),
    )

    body
  }

  let parse_result =
    json.parse(result.unwrap(body, ""), {
      use subscribe_to <- decode.field(
        "subscribe",
        decode.list(category.decoder_pt_br()),
      )
      decode.success(subscribe_to)
    })

  #(
    State(user_uuid:, subscribed_categories: result.unwrap(parse_result, [])),
    option.Some(selector),
  )
}

// ON CLOSE --------------------------------------------------------------------

fn ws_on_close(
  state _state: State,
  ctx _ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.Msg),
) -> Nil {
  group_registry.leave(registry, topic, [process.self()])
}

// HELPERS ---------------------------------------------------------------------

fn build_error_response(
  error_msg: String,
  status: Int,
) -> response.Response(mist.ResponseData) {
  error_msg
  |> bytes_tree.from_string
  |> mist.Bytes
  |> response.set_body(response.new(status), _)
}

fn handle_ws_error(err: WebSocketError) -> response.Response(mist.ResponseData) {
  case err {
    InvalidUuid(id) ->
      build_error_response("Usuário possui Uuid inválido: " <> id, 401)
    InvalidSignature ->
      build_error_response("Falha ao desencriptografar o token de acesso", 401)
    InvalidUtf8 ->
      build_error_response("Token de acesso possui formato inválido", 404)
    MissingCookie -> build_error_response("Cookie de autorização ausente", 401)
  }
}
