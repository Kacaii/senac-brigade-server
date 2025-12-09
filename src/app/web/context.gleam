import app/web/socket/message
import gleam/erlang/process
import group_registry
import pog

/// Holds any additional data that the request handlers need in addition to the request:
/// Like configurations, database connections, and others
pub type Context {
  Context(
    ///   BEAM's private directory for static files
    static_directory: String,
    ///   Postgres's connection pool
    db: pog.Connection,
    ///   Key for encryption and decryption
    secret_key_base: String,
    ///   Process registry
    registry_name: process.Name(group_registry.Message(message.Msg)),
    ///   Enviroment where the code is running on
    env: Enviroment,
  )
}

///   Enviroment where the code is running on
pub type Enviroment {
  ///   Code is running locally
  Dev
  ///   Code is running in production
  Production
}
