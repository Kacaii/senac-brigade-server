import app/routes/user
import app/web/context.{type Context}
import gleam/bit_array
import gleam/bytes_tree
import gleam/crypto
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import group_registry
import mist
import youid/uuid

const group_topic = "active_users"

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

type ConnectionState {
  ConnectionState(user_uuid: uuid.Uuid)
}

fn handle_connection(
  req: request.Request(mist.Connection),
  ctx: Context,
  user_uuid: uuid.Uuid,
  registry: group_registry.GroupRegistry(context.ServerMessage),
) -> response.Response(mist.ResponseData) {
  mist.websocket(
    request: req,
    on_init: ws_on_init(_, req, ctx, user_uuid, registry),
    on_close: ws_on_close(_, ctx, registry),
    handler: fn(state, msg, conn) {
      ws_handler(state, msg, conn, ctx, registry)
    },
  )
}

fn ws_on_init(
  conn _conn: mist.WebsocketConnection,
  req _req: request.Request(mist.Connection),
  ctx _ctx: Context,
  user_uuid user_uuid: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(context.ServerMessage),
) -> #(ConnectionState, option.Option(process.Selector(context.ServerMessage))) {
  let self = process.self()
  let group_subject = group_registry.join(registry, group_topic, self)

  let user_subject =
    group_registry.join(registry, uuid.to_string(user_uuid), self)

  let selector =
    process.new_selector()
    |> process.select(group_subject)
    |> process.select(user_subject)

  #(ConnectionState(user_uuid:), option.Some(selector))
}

fn ws_on_close(
  state _state: ConnectionState,
  ctx _ctx: Context,
  registry registry: group_registry.GroupRegistry(context.ServerMessage),
) -> Nil {
  group_registry.leave(registry, group_topic, [process.self()])
}

fn ws_handler(
  state state: ConnectionState,
  msg msg: mist.WebsocketMessage(context.ServerMessage),
  ws_conn conn: mist.WebsocketConnection,
  ctx _ctx: Context,
  registry _registry: group_registry.GroupRegistry(context.ServerMessage),
) -> mist.Next(ConnectionState, context.ServerMessage) {
  case msg {
    mist.Text(_) -> mist.continue(state)
    mist.Binary(_) -> mist.continue(state)
    mist.Custom(msg) -> handle_custom_msg(state, msg, conn)
    mist.Closed | mist.Shutdown -> mist.stop()
  }
}

fn handle_custom_msg(
  state: ConnectionState,
  msg: context.ServerMessage,
  conn: mist.WebsocketConnection,
) -> mist.Next(ConnectionState, context.ServerMessage) {
  case msg {
    context.Ping -> {
      let msg_result = mist.send_text_frame(conn, "  Pong")
      case msg_result {
        Error(_) -> mist.stop_abnormal("Failed to reply with pong")
        Ok(_) -> mist.continue(state)
      }
    }

    context.Broadcast(message) -> {
      let msg_result = mist.send_text_frame(conn, message)
      case msg_result {
        Error(_) -> mist.stop_abnormal("Failed to broadcast message")
        Ok(_) -> mist.continue(state)
      }
    }

    context.UserAssignedToBrigade(user_id:, brigade_id:) -> {
      // Build notification
      let data_type_json = "assigned_to_brigade" |> json.string
      let user_id_json = uuid.to_string(user_id) |> json.string
      let brigade_id_json = uuid.to_string(brigade_id) |> json.string

      // Construct the body
      let body =
        json.object([
          #("data_type", data_type_json),
          #("user_id", user_id_json),
          #("brigade_id", brigade_id_json),
        ])
        |> json.to_string

      let msg_result = mist.send_text_frame(conn, body)
      case msg_result {
        Error(_) -> mist.stop_abnormal("Failed to notify assignment to user")
        Ok(_) -> mist.continue(state)
      }
    }
    context.UserAssignedToOccurrence(user_id:, occurrence_id:) -> {
      // Build notification
      let data_type_json = "assigned_to_occurrence" |> json.string
      let user_id_json = uuid.to_string(user_id) |> json.string
      let occurrence_id_json = uuid.to_string(occurrence_id) |> json.string

      // Construct the body
      let body =
        json.object([
          #("data_type", data_type_json),
          #("user_id", user_id_json),
          #("occurrence_id", occurrence_id_json),
        ])
        |> json.to_string

      let msg_result = mist.send_text_frame(conn, body)
      case msg_result {
        Error(_) -> mist.stop_abnormal("Failed to notify assignment to user")
        Ok(_) -> mist.continue(state)
      }
    }
  }
}

fn handle_ws_error(err: WebSocketError) -> response.Response(mist.ResponseData) {
  case err {
    InvalidUuid(id) ->
      build_response("Usuário possui Uuid inválido: " <> id, 401)
    InvalidSignature ->
      build_response("Falha ao desencriptografar o token de acesso", 401)
    InvalidUtf8 ->
      build_response("Token de acesso possui formato inválido", 422)
    MissingCookie -> build_response("Cookie de autorização ausente", 401)
  }
}

fn build_response(
  error_msg: String,
  status: Int,
) -> response.Response(mist.ResponseData) {
  error_msg
  |> bytes_tree.from_string
  |> mist.Bytes
  |> response.set_body(response.new(status), _)
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
