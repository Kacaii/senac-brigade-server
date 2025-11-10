import app/web/socket/message as msg
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
    registry_name: process.Name(group_registry.Message(msg.ServerMessage)),
  )
}
