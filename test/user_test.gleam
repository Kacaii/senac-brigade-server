import app/routes/user/get_all_users
import app/routes/user/login
import app_test.{global_data}
import gleam/http
import gleam/http/response
import gleam/list
import gleam/string
import wisp/simulate

pub fn login_test() {
  let ctx = global_data()

  let req =
    simulate.browser_request(http.Post, "/user/login")
    |> simulate.form_body([#("matricula", "000"), #("senha", "aluno")])

  let resp = login.handle_request(req, ctx)

  assert resp.status == 200 as "Status should be 200"

  let cookies = response.get_cookies(resp)
  assert cookies != [] as "Server should set a session Cookie on login"

  let assert Ok(_) = {
    use cookie <- list.find(cookies)
    case cookie {
      #("USER_ID", _) -> True
      #(_, _) -> False
    }
  }
    as "No Cookie named USER_ID was found in the response"
}

pub fn get_all_user_test() {
  let ctx = global_data()

  let req = simulate.browser_request(http.Get, "/admin/users")
  let resp = get_all_users.handle_request(req, ctx)

  let body = simulate.read_body(resp)

  assert resp.status == 401 as "Access restricted to Admins"
  assert string.is_empty(body) == False

  // -------------------------------------------------------
  let with_auth = app_test.with_authorization()

  let resp = get_all_users.handle_request(with_auth, ctx)

  let body = simulate.read_body(resp)
  assert resp.status == 200
  assert string.is_empty(body) == False

  todo as "Check the payload"
}
