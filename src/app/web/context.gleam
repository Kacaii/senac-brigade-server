import gleam/erlang/process
import group_registry
import pog
import youid/uuid

/// Holds any additional data that the request handlers need in addition to the request:
/// Like API Keys, configurations,  database connections, and others
pub type Context {
  Context(
    static_directory: String,
    conn: pog.Connection,
    secret_key_base: String,
    registry_name: process.Name(group_registry.Message(ServerMessage)),
  )
}

pub type ServerMessage {
  Broadcast(String)
  UserAssignedToBrigade(user_id: uuid.Uuid, brigade_id: uuid.Uuid)
  Ping
}
