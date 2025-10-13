import app/routes/user/login
import app_test.{global_data}
import gleam/http
import gleam/http/response
import gleam/list
import wisp/simulate

pub fn login_test() {
  let ctx = global_data()

  let req =
    simulate.browser_request(http.Post, "/api/login")
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
