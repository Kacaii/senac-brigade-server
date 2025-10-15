import app/router
import app_test
import gleam/dynamic/decode
import gleam/http
import gleam/http/response
import gleam/json
import gleam/list
import gleam/string
import wisp/simulate

pub fn login_test() {
  let ctx = app_test.global_data()

  let req =
    simulate.browser_request(http.Post, "/user/login")
    |> simulate.form_body([#("matricula", "000"), #("senha", "aluno")])

  let resp = router.handle_request(req, ctx)

  assert resp.status == 200 as "Status should be 200"

  let cookies = response.get_cookies(resp)
  assert cookies != [] as "Server should set a session Cookie on login"

  let assert Ok(_) = list.key_find(cookies, "USER_ID")
    as "No Cookie named USER_ID was found in the server response"
}

pub fn get_all_users_test() {
  let ctx = app_test.global_data()

  let req = simulate.browser_request(http.Get, "/admin/users")
  let resp = router.handle_request(req, ctx)

  assert resp.status == 401 as "Access only provided to Admin users"

  // -------------------------------------------------------
  let with_auth = app_test.with_authorization(next: req)
  let resp = router.handle_request(with_auth, ctx)

  let body = simulate.read_body(resp)
  assert string.is_empty(body) == False as "Response body should not be empty"

  assert resp.status == 200 as "Endpoint access should be available for Admins"

  let assert Ok(_) =
    json.parse(
      body,
      decode.list({
        use _ <- decode.field("id", decode.string)
        use _ <- decode.field("full_name", decode.string)
        use _ <- decode.field("registration", decode.string)
        use _ <- decode.optional_field("email", "null", decode.string)
        use _ <- decode.field("user_role", decode.string)
        decode.success(Nil)
      }),
    )
    as "Response should contain valid JSON data"
}
