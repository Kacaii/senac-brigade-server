import app/web/socket/message as server_msg
import app/web/socket/routes/notification/message as notification_msg
import gleam/erlang/process
import group_registry
import pog

/// Holds any additional data that the request handlers need in addition to the request:
/// Like API Keys, configurations,  database connections, and others
pub type Context {
  Context(
    static_directory: String,
    db: pog.Connection,
    secret_key_base: String,
    registry_name: process.Name(group_registry.Message(server_msg.Msg)),
    notification_registry_name: process.Name(
      group_registry.Message(notification_msg.Msg),
    ),
  )
}
