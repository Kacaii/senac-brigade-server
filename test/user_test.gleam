import app/router
import app/routes/role
import app/routes/user
import app/routes/user/sql
import app_test
import dummy
import gleam/dynamic/decode
import gleam/http
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/string
import wisp
import wisp/simulate
import youid/uuid

pub fn login_test() {
  let ctx = app_test.global_data()

  let req =
    simulate.browser_request(http.Post, "/user/login")
    |> simulate.form_body([#("matricula", "000"), #("senha", "aluno")])

  let resp = router.handle_request(req, ctx)
  assert resp.status == 200 as "Status should be 200"

  let body = simulate.read_body(resp)

  let assert Ok(_) =
    json.parse(body, {
      use maybe_uuid <- decode.field("id", decode.string)
      let assert Ok(_) = uuid.from_string(maybe_uuid) as "Invalid UUID"

      use maybe_role <- decode.field("role", decode.string)
      let assert Ok(_) = role.from_string_pt_br(maybe_role)
        as "Invalid user Role"

      decode.success(Nil)
    })
    as "Response should contain valid JSON data"

  let cookies = response.get_cookies(resp)
  assert cookies != [] as "Server should set a session Cookie on login"

  let assert Ok(_) = list.key_find(cookies, user.uuid_cookie_name)
    as "No Cookie named USER_ID was found in the server response"
}

pub fn signup_test() {
  let ctx = app_test.global_data()

  let password = wisp.random_string(10)

  let available_roles = [
    role.Admin,
    role.Analyst,
    role.Captain,
    role.Developer,
    role.Firefighter,
    role.Sargeant,
  ]

  // Try to create an user for every available user role
  list.each(available_roles, fn(designed_role) {
    let req =
      simulate.browser_request(http.Post, "/admin/signup")
      |> simulate.form_body([
        #("nome", wisp.random_string(10)),
        #("matricula", int.random(111) |> int.to_string),
        #("telefone", int.random(9_999_999_999) |> int.to_string),
        #("email", wisp.random_string(5) <> "@email.com"),
        #("senha", password),
        #("confirma_senha", password),
        #("cargo", role.to_string_pt_br(designed_role)),
      ])

    let resp = router.handle_request(req, ctx)
    assert resp.status == 401 as "Endpoint access should be restricted"

    //   AUTH -------------------------------------------------------------------
    let with_auth = app_test.with_authorization(next: req)
    let resp = router.handle_request(with_auth, ctx)
    assert resp.status == 201 as "Response should be 201 Created"

    let body = simulate.read_body(resp)

    let assert Ok(parsed_response) =
      json.parse(body, {
        use id <- decode.field("id", decode.string)
        decode.success(id)
      })
      as "Response should contain valid JSON data"

    // 󰃢  CLEANUP ----------------------------------------------------------------
    let assert Ok(created_user_uuid) = uuid.from_string(parsed_response)
      as "JSON response should contain a valid UUID"

    let assert Ok(returned) = sql.delete_user_by_id(ctx.conn, created_user_uuid)
      as "Failed to delete user after insertion"

    let assert Ok(deleted_user) = list.first(returned.rows)
      as "Database returned no results after deleting the new user"

    assert deleted_user.id == created_user_uuid as "Deleted the wrong user"
  })
}

pub fn get_all_users_test() {
  let ctx = app_test.global_data()

  let req = simulate.browser_request(http.Get, "/admin/users")
  let resp = router.handle_request(req, ctx)

  assert resp.status == 401 as "Access only provided to Admin users"

  // -------------------------------------------------------
  let with_auth = app_test.with_authorization(next: req)
  let resp = router.handle_request(with_auth, ctx)
  assert resp.status == 200 as "Endpoint access should be available for Admins"

  let body = simulate.read_body(resp)
  assert string.is_empty(body) == False as "Response body should not be empty"

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

pub fn update_user_profile_test() {
  let ctx = app_test.global_data()
  let login_path = "/user/login"
  let signup_path = "/admin/signup"

  // 󰚩  DUMMY ------------------------------------------------------------------
  let dummy_password = "aluno"
  let dummy_registration = "001"
  let dummy_phone = "8190000000"
  let dummy_email = "wibble@email.com"

  let new_user_req =
    simulate.browser_request(http.Post, signup_path)
    |> simulate.form_body([
      #("nome", wisp.random_string(10)),
      #("matricula", dummy_registration),
      #("telefone", dummy_phone),
      #("email", dummy_email),
      #("senha", dummy_password),
      #("confirma_senha", dummy_password),
      #("cargo", role.to_string_pt_br(role.Firefighter)),
    ])

  let with_auth = app_test.with_authorization(new_user_req)
  let new_user_resp = router.handle_request(with_auth, ctx)

  let assert Ok(new_user) =
    json.parse(simulate.read_body(new_user_resp), {
      use maybe_uuid <- decode.field("id", decode.string)
      case uuid.from_string(maybe_uuid) {
        Error(_) -> decode.failure(uuid.v7(), "user_uuid")
        Ok(value) -> decode.success(value)
      }
    })
    as "Response contain invalid JSON"

  let path = "/user/profile"
  let login_req =
    simulate.browser_request(http.Post, login_path)
    |> simulate.form_body([
      #("matricula", dummy_registration),
      #("senha", dummy_password),
    ])
  let login_resp = router.handle_request(login_req, ctx)

  // UPDATING DUMMY ------------------------------------------------------------
  let new_name = wisp.random_string(8)
  let new_email = wisp.random_string(6) <> "@email.com"
  let new_phone = int.random(11) |> int.to_string

  let req =
    simulate.browser_request(http.Put, path)
    |> simulate.json_body(
      json.object([
        #("full_name", json.string(new_name)),
        #("email", json.string(new_email)),
        #("phone", json.string(new_phone)),
      ]),
    )
    |> simulate.session(login_req, login_resp)

  let resp = router.handle_request(req, ctx)

  // ASSERTIONS ----------------------------------------------------------------
  assert resp.status == 200 as "Status should be HTTP 200 OK"
  let body = simulate.read_body(resp)

  let assert Ok(_) =
    json.parse(body, {
      use returned_full_name <- decode.field("full_name", decode.string)
      use returned_email <- decode.field("email", decode.string)
      use returned_phone <- decode.field("phone", decode.string)

      assert returned_full_name == new_name as "Name was not updated"
      assert returned_email == new_email as "Email was not updated"
      assert returned_phone == new_phone as "Phone was not updated"

      decode.success(Nil)
    })
    as "Response should contain valid JSON"

  // 󰃢  CLEANUP ----------------------------------------------------------------
  dummy.clean_user(ctx, new_user)
}
