import app
import app/router
import app/web/context.{type Context, Context}
import gleam/erlang/process
import gleam/http
import gleeunit
import global_value
import pog
import wisp
import wisp/simulate

pub const n_tests = 25

pub fn main() -> Nil {
  gleeunit.main()
}

/// Global context data used in unit tests
pub fn global_data() -> Context {
  global_value.create_with_unique_name("global_context", fn() {
    let db_process_name = process.new_name("db_conn")
    let registry_name = process.new_name("registry")
    let assert Ok(config) = app.read_connection_uri(db_process_name)

    let conn = pog.named_connection(db_process_name)
    let assert Ok(_) = pog.start(config)

    Context(static_directory: app.static_directory(), conn:, registry_name:)
  })
}

///   Create a request with admin privileges
pub fn with_authorization(next req: wisp.Request) -> wisp.Request {
  let ctx = global_data()

  let login_req =
    simulate.browser_request(http.Post, "/user/login")
    |> simulate.form_body([#("matricula", "000"), #("senha", "aluno")])

  let login_resp = router.handle_request(login_req, ctx)

  // Continue the session after being logged in
  simulate.session(req, login_req, login_resp)
}
