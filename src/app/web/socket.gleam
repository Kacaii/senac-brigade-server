import app/domain/notification/sql as notif_sql
import app/domain/occurrence/category
import app/domain/user
import app/domain/user/sql as user_sql
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
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp
import group_registry
import mist
import pog
import youid/uuid

pub const ws_topic = "active_users"

pub opaque type WebSocketError {
  /// 󱛪  Session cookie was not found
  MissingCookie
  /// 󰣮  Failed to verify signed message
  InvalidSignature
  /// 󱦃  The signed message could not be properly decrypted
  InvalidUtf8
  /// 󰘨  Session token has invalid Uuid fomat
  InvalidUuid(String)
  /// 󰆼  Failed to access the DataBase
  Database(pog.QueryError)
  ///   Content-length header is missing
  MissingContentLength
  ///   Content-length header is not a valid integer value
  InvalidContentLength(String)
  ///   Failed to read the request body
  ReadError(mist.ReadError)
}

/// 󱘖  Stabilishes a websocket connection with the client
pub fn handle_request(
  req: request.Request(mist.Connection),
  ctx: Context,
) -> response.Response(mist.ResponseData) {
  let registry = group_registry.get_registry(ctx.registry_name)

  case extract_uuid(req, ctx) {
    Error(err) -> handle_error(err)
    Ok(user_uuid) -> handle_connection(req, ctx, user_uuid, registry)
  }
}

///   Current state of the websocket connection
pub opaque type State {
  State(
    ///   User connected to this socket
    user_uuid: uuid.Uuid,
    ///   Selector being used for the process
    selector: option.Option(process.Selector(msg.Msg)),
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
  case setup_initial_state(ctx, user_uuid) {
    Error(err) -> handle_error(err)
    Ok(state) ->
      case request.path_segments(req) {
        ["ws"] ->
          mist.websocket(
            request: req,
            on_init: ws_on_init(_, req:, ctx:, registry:, state:),
            on_close: ws_on_close(_, ctx:, registry:),
            handler: fn(state, msg, conn) {
              ws_handler(state:, msg:, conn:, ctx:, registry:)
            },
          )

        _ -> send_response("Not found", 404)
      }
  }
}

/// Queries the Database and builds the initial state of the user
fn setup_initial_state(
  ctx: Context,
  user_uuid: uuid.Uuid,
) -> Result(State, WebSocketError) {
  use brigade_list <- result.try(fetch_brigades(ctx, user_uuid))
  use subscribed <- result.map(fetch_categories(ctx, user_uuid))
  State(user_uuid:, subscribed:, brigade_list:, selector: option.None)
}

fn ws_handler(
  state state: State,
  msg msg: mist.WebsocketMessage(msg.Msg),
  conn conn: mist.WebsocketConnection,
  ctx ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.Msg),
) -> mist.Next(State, msg.Msg) {
  case msg {
    mist.Closed | mist.Shutdown | mist.Text(":q") -> mist.stop()
    mist.Text(_) -> mist.continue(state)
    mist.Binary(_) -> mist.continue(state)
    mist.Custom(msg) -> handle_msg(state, msg, conn, ctx, registry)
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

    msg.Domain(event) -> handle_domain_event(state, conn, event)
  }
}

fn handle_domain_event(
  state: State,
  conn: mist.WebsocketConnection,
  msg: msg.DomainEvent,
) -> mist.Next(State, msg.Msg) {
  case msg {
    msg.UserAssignedToBrigade(user_id:, brigade_id:) -> {
      let brigade_list = [brigade_id, ..state.brigade_list]
      let state = State(..state, brigade_list:)

      send_envelope(
        state:,
        conn:,
        data_type: "brigade:assigned",
        data: json.object([
          #("user_id", uuid.to_string(user_id) |> json.string),
          #("brigade_id", uuid.to_string(brigade_id) |> json.string),
        ]),
      )
    }

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

    msg.OccurrenceCreated(id:, category:) -> {
      use <- bool.guard(
        when: list.any(state.subscribed, fn(sub) { sub == category }),
        return: mist.continue(state),
      )

      send_envelope(
        state:,
        conn:,
        data_type: "occurrence:new",
        data: json.object([
          #("id", json.string(uuid.to_string(id))),
          #("occ_type", json.string(category.to_string_pt_br(category))),
        ]),
      )
    }

    msg.OccurrenceResolved(id:, when:) -> {
      let timestamp_json = {
        use time <- json.nullable(when)
        json.float(timestamp.to_unix_seconds(time))
      }

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

    msg.OccurrenceReopened(id:, when:) -> {
      let timestamp_json = {
        use time <- json.nullable(when)
        json.float(timestamp.to_unix_seconds(time))
      }

      send_envelope(
        state:,
        conn:,
        data_type: "occurrence:reopened",
        data: json.object([
          #("id", json.string(uuid.to_string(id))),
          #("timestamp", timestamp_json),
        ]),
      )
    }
  }
}

fn send_envelope(
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

fn extract_uuid(
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

  uuid.from_string(maybe_uuid_str)
  |> result.replace_error(InvalidUuid(maybe_uuid_str))
}

// ON INIT ---------------------------------------------------------------------

fn ws_on_init(
  conn _conn: mist.WebsocketConnection,
  req _req: request.Request(mist.Connection),
  ctx _ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.Msg),
  state state: State,
) -> #(State, option.Option(process.Selector(msg.Msg))) {
  let self = process.self()
  let group_subject = group_registry.join(registry, ws_topic, self)

  let user_topic = "user:" <> uuid.to_string(state.user_uuid)
  let user_subject = group_registry.join(registry, user_topic, self)

  let selector =
    process.new_selector()
    |> process.select(group_subject)
    |> process.select(user_subject)

  let selector = {
    use acc, value <- list.fold(over: state.subscribed, from: selector)
    let topic = "occurrence:new_" <> category.to_string(value)

    let occ_subj = group_registry.join(registry, topic, self)
    process.select(acc, occ_subj)
  }

  #(state, option.Some(selector))
}

/// 󰀖  Find all brigades that an user is assigned to
fn fetch_brigades(
  ctx: Context,
  for: uuid.Uuid,
) -> Result(List(uuid.Uuid), WebSocketError) {
  use returned <- result.map(
    user_sql.query_user_brigades(ctx.db, for)
    |> result.map_error(Database),
  )

  list.map(returned.rows, fn(row) { row.brigade_id })
}

/// 󰩉  Find all occurrence categories an user wants to be notified of
fn fetch_categories(
  ctx: Context,
  for: uuid.Uuid,
) -> Result(List(category.Category), WebSocketError) {
  use returned <- result.map(
    notif_sql.query_active_notifications(ctx.db, for)
    |> result.map_error(Database),
  )

  use row <- list.map(returned.rows)
  case row.notification_type {
    notif_sql.Emergency -> category.MedicEmergency
    notif_sql.Fire -> category.Fire
    notif_sql.Other -> category.Other
    notif_sql.Traffic -> category.TrafficAccident
  }
}

// ON CLOSE --------------------------------------------------------------------

fn ws_on_close(
  state state: State,
  ctx _ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.Msg),
) -> Nil {
  let self = process.self()

  group_registry.leave(registry, ws_topic, [self])

  let user_topic = "user:" <> uuid.to_string(state.user_uuid)
  group_registry.leave(registry, user_topic, [self])

  use subscribed_to <- list.each(state.subscribed)
  let topic = "occurrence:new_" <> category.to_string(subscribed_to)
  group_registry.leave(registry, topic, [self])
}

// HELPERS ---------------------------------------------------------------------

///   Broadcast a message to all active users
pub fn broadcast(
  registry registry: group_registry.GroupRegistry(msg.Msg),
  message message: msg.Msg,
) -> Nil {
  let members = group_registry.members(registry, ws_topic)
  members |> list.each(process.send(_, message))
}

fn send_response(
  body: String,
  status: Int,
) -> response.Response(mist.ResponseData) {
  body
  |> bytes_tree.from_string
  |> mist.Bytes
  |> response.set_body(response.new(status), _)
}

fn handle_error(err: WebSocketError) -> response.Response(mist.ResponseData) {
  case err {
    InvalidUuid(id) -> {
      let body = "Usuário possui Uuid inválido: " <> id
      send_response(body, 401)
    }

    InvalidSignature ->
      "Falha ao desencriptografar o token de acesso"
      |> send_response(401)

    InvalidUtf8 ->
      "Token de acesso possui formato inválido"
      |> send_response(404)

    MissingCookie ->
      "Cookie de autorização se encontra ausente"
      |> send_response(401)

    InvalidContentLength(header) -> {
      let body = "Header content-length inválido: " <> header
      send_response(body, 400)
    }

    MissingContentLength ->
      "Header content-length ausente"
      |> send_response(404)

    ReadError(mist.ExcessBody) ->
      "Corpo do request é longo demais"
      |> send_response(400)

    ReadError(mist.MalformedBody) ->
      "Corpo do request se encontra mal construído"
      |> send_response(422)

    Database(err) -> handle_database_error(err)
  }
}

fn handle_database_error(
  err: pog.QueryError,
) -> response.Response(mist.ResponseData) {
  case err {
    pog.ConnectionUnavailable ->
      "Conexão com o banco de dados não disponível"
      |> send_response(500)

    pog.PostgresqlError(code:, name:, message:) ->
      json.object([
        #("code", json.string(code)),
        #("name", json.string(name)),
        #("message", json.string(message)),
      ])
      |> json.to_string
      |> send_response(500)

    pog.QueryTimeout ->
      "O servidor demorou muito pra responder"
      |> send_response(500)

    pog.ConstraintViolated(message:, constraint:, detail:) ->
      json.object([
        #("message", json.string(message)),
        #("constraint", json.string(constraint)),
        #("detail", json.string(detail)),
      ])
      |> json.to_string
      |> send_response(409)

    pog.UnexpectedArgumentCount(expected:, got:) -> {
      json.object([
        #("expected", json.int(expected)),
        #("got", json.int(got)),
      ])
      |> json.to_string
      |> send_response(400)
    }

    pog.UnexpectedArgumentType(expected:, got:) -> {
      json.object([
        #("expected", json.string(expected)),
        #("got", json.string(got)),
      ])
      |> json.to_string
      |> send_response(400)
    }

    pog.UnexpectedResultType(err_list) -> handle_decode_error(err_list)
  }
}

pub fn handle_decode_error(
  decode_errors: List(decode.DecodeError),
) -> response.Response(mist.ResponseData) {
  case list.first(decode_errors) {
    Error(_) -> send_response("Ok", 200)
    Ok(err) ->
      json.object([
        #("expected", json.string(err.expected)),
        #("found", json.string(err.found)),
        #("path", json.string(string.join(err.path, "/"))),
      ])
      |> json.to_string
      |> send_response(400)
  }
}

pub fn read_body(req: request.Request(mist.Connection)) {
  use header <- result.try(
    request.get_header(req, "content-length")
    |> result.replace_error(MissingContentLength),
  )

  use content_length <- result.try(
    int.parse(header)
    |> result.replace_error(InvalidContentLength(header)),
  )

  use req <- result.try(
    mist.read_body(req, content_length)
    |> result.map_error(ReadError),
  )

  bit_array.to_string(req.body)
  |> result.replace_error(InvalidUtf8)
}
