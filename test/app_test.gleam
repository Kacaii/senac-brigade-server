import app
import app/routes/user/login
import app/web
import gleam/erlang/process
import gleam/http
import gleeunit
import global_value
import pog
import wisp
import wisp/simulate

pub fn main() -> Nil {
  gleeunit.main()
}

/// Global context data used in unit tests
pub fn global_data() -> web.Context {
  global_value.create_with_unique_name("global_context", fn() {
    let db_process_name = process.new_name("db_conn")
    let assert Ok(config) = app.read_connection_uri(db_process_name)

    let conn = pog.named_connection(db_process_name)
    let assert Ok(_) = pog.start(config)

    web.Context(static_directory: app.static_directory(), conn:)
  })
}

///   Create a request with admin privileges
pub fn with_authorization() -> wisp.Request {
  let ctx = global_data()

  let login_req =
    simulate.browser_request(http.Post, "/api/login")
    |> simulate.form_body([#("matricula", "000"), #("senha", "aluno")])

  let login_resp = login.handle_request(login_req, ctx)

  // Continue the session after being logged in
  simulate.session(
    simulate.browser_request(http.Get, "/user/login"),
    login_req,
    login_resp,
  )
}
