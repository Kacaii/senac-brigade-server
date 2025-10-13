import app
import app/web
import gleam/erlang/process
import gleeunit
import global_value
import pog

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn global_data() -> web.Context {
  global_value.create_with_unique_name("global_context", fn() {
    let db_process_name = process.new_name("db_conn")
    let assert Ok(config) = app.read_connection_uri(db_process_name)

    let conn = pog.named_connection(db_process_name)
    let assert Ok(_) = pog.start(config)

    web.Context(static_directory: app.static_directory(), conn:)
  })
}
