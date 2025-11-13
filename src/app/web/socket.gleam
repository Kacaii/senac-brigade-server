import app/routes/notification/sql as notif_sql
import app/routes/occurrence/category
import app/routes/user
import app/routes/user/sql as user_sql
import app/web/context.{type Context}
import app/web/socket/envelope
import app/web/socket/message as msg
import gleam/bit_array
import gleam/bool
import gleam/bytes_tree
import gleam/crypto
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/time/timestamp
import group_registry
import mist
import pog
import youid/uuid

pub const ws_topic = "active_users"

/// Connecting to a websocket can fail
pub opaque type WebSocketError {
  /// 󱛪  Session cookie was not found
  MissingCookie
  /// 󰣮  Failed to verify signed message
  InvalidSignature
  /// 󱦃  The signed message could not be properly decrypted
  InvalidUtf8
  /// 󰘨  Session token has invalid Uuid fomat
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
    subscribed: List(category.Category),
    ///   Brigades that an user has been assigned to
    brigade_list: List(uuid.Uuid),
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
    mist.Custom(msg) -> handle_msg(state, msg, ws_conn, ctx, registry)
    mist.Closed | mist.Shutdown -> mist.stop()
  }
}

fn handle_msg(
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
        data_type: "brigade:assigned",
        data: json.object([
          #("user_id", uuid.to_string(user_id) |> json.string),
          #("brigade_id", uuid.to_string(brigade_id) |> json.string),
        ]),
      )

    msg.UserAssignedToOccurrence(user_id:, occurrence_id:) ->
      send_envelope(
        state:,
        conn:,
        data_type: "occurrence:assigned",
        data: json.object([
          #("user_id", uuid.to_string(user_id) |> json.string),
          #("occurrence_id", uuid.to_string(occurrence_id) |> json.string),
        ]),
      )

    msg.NewOccurrence(occ_id:, occ_type:) -> {
      use <- bool.guard(
        when: list.any(state.subscribed, fn(sub) { sub == occ_type }),
        return: mist.continue(state),
      )

      send_envelope(
        state:,
        conn:,
        data_type: "occurrence:new",
        data: json.object([
          #("id", json.string(uuid.to_string(occ_id))),
          #("occ_type", json.string(category.to_string_pt_br(occ_type))),
        ]),
      )
    }

    msg.OccurrenceResolved(id:, when:) -> {
      let timestamp_json =
        json.nullable(when, fn(time) {
          timestamp.to_unix_seconds(time) |> json.float
        })

      send_envelope(
        state:,
        conn:,
        data_type: "occurrence:resolved",
        data: json.object([
          #("id", json.string(uuid.to_string(id))),
          #("timestamp", timestamp_json),
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
  let meta =
    envelope.MetaData(
      timestamp: timestamp.system_time(),
      request_id: state.user_uuid,
    )

  let frame_result =
    envelope.Envelope(data_type:, data:, meta:)
    |> envelope.to_json
    |> json.to_string
    |> mist.send_text_frame(conn, _)

  case frame_result {
    Error(_) -> mist.stop_abnormal("Failed to send text frame")
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
  req _req: request.Request(mist.Connection),
  ctx ctx: Context,
  user_uuid user_uuid: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(msg.Msg),
) -> #(State, option.Option(process.Selector(msg.Msg))) {
  let self = process.self()
  let group_subject = group_registry.join(registry, ws_topic, self)

  let user_topic = uuid.to_string(user_uuid)
  let user_subject = group_registry.join(registry, user_topic, self)

  let selector =
    process.new_selector()
    |> process.select(group_subject)
    |> process.select(user_subject)

  let brigade_list =
    fetch_brigades(ctx, user_uuid)
    |> result.unwrap([])

  let subscribed =
    fetch_categories(ctx, user_uuid)
    |> result.unwrap([])

  #(State(user_uuid:, subscribed:, brigade_list:), option.Some(selector))
}

pub fn read_body(
  req: request.Request(mist.Connection),
) -> Result(String, mist.ReadError) {
  let req_result =
    request.get_header(req, "content-length")
    |> result.try(int.parse)
    |> result.unwrap(0)
    |> mist.read_body(req, _)

  result.map(req_result, fn(req) {
    req.body
    |> bit_array.to_string
    |> result.unwrap("")
  })
}

fn fetch_brigades(
  ctx: Context,
  for: uuid.Uuid,
) -> Result(List(uuid.Uuid), pog.QueryError) {
  use returned <- result.map(user_sql.query_user_brigades(ctx.db, for))
  list.map(returned.rows, fn(row) { row.brigade_id })
}

fn fetch_categories(
  ctx: Context,
  for: uuid.Uuid,
) -> Result(List(category.Category), pog.QueryError) {
  use returned <- result.try(notif_sql.query_active_notifications(ctx.db, for))

  let categories =
    list.map(returned.rows, fn(row) {
      case row.notification_type {
        notif_sql.Emergency -> category.MedicEmergency
        notif_sql.Fire -> category.Fire
        notif_sql.Other -> category.Other
        notif_sql.Traffic -> category.TrafficAccident
      }
    })

  Ok(categories)
}

// ON CLOSE --------------------------------------------------------------------

fn ws_on_close(
  state state: State,
  ctx _ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.Msg),
) -> Nil {
  let self = process.self()
  group_registry.leave(registry, ws_topic, [self])
  group_registry.leave(registry, uuid.to_string(state.user_uuid), [self])
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
