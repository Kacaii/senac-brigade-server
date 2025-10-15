import app/routes/user/get_all_users
import app/routes/user/login
import app_test.{global_data}
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/string
import wisp/simulate
import gleam/dynamic/decode
import gleam/json

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
  let with_auth =
    app_test.with_authorization()
    |> request.set_method(req.method)
    |> request.set_path(req.path)

  let resp = get_all_users.handle_request(with_auth, ctx)

  let body = simulate.read_body(resp)
  assert string.is_empty(body) == False

  assert resp.status == 200 as "Endpoint access should be available for admins"
  let assert Ok(_) =
   json.parse(body, decode.list({
    use _ <- decode.field("id", decode.string)
    use _ <- decode.field("full_name", decode.string)
    use _ <- decode.field("registration", decode.string)
    use _ <- decode.optional_field("email", "n/a", decode.string)
    use _ <- decode.field("user_role", decode.string)
    decode.success(Nil)
  }))
  as "Response should contain valid (USER)JSON data"
}
