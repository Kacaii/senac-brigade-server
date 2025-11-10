import app/router
import app/routes/role
import app/routes/user/sql as u_sql
import app_dev/sql as dev_sql
import app_test
import dummy
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import wisp
import wisp/simulate
import youid/uuid

pub fn admin_update_user_test() {
  let ctx = app_test.global_data()
  use _ <- list.each(list.range(1, app_test.n_tests))

  // DUMMY USER ----------------------------------------------------------------
  let dummy_user_id = dummy.random_user(ctx.db)
  let path = "/admin/users/" <> uuid.to_string(dummy_user_id)

  // Data
  let new_full_name = "wibble"
  let new_email = wisp.random_string(12) <> "@email.com"
  let new_role = dummy.random_role()
  let new_registration = wisp.random_string(6)
  let new_status = False

  // REQUEST -------------------------------------------------------------------
  let req =
    simulate.browser_request(http.Put, path)
    |> simulate.json_body(
      json.object([
        #("full_name", json.string(new_full_name)),
        #("email", json.string(new_email)),
        #("user_role", json.string(role.to_string(new_role))),
        #("registration", json.string(new_registration)),
        #("is_active", json.bool(new_status)),
      ]),
    )

  let resp = router.handle_request(req, ctx)
  assert resp.status == 401
    as "Endpoint only accessible for authenticated Admin users"

  let req = app_test.with_authorization(req)
  let resp = router.handle_request(req, ctx)

  assert resp.status == 200 as "Response should be HTTP 200 OK"

  let body = simulate.read_body(resp)
  let assert Ok(_) =
    json.parse(body, {
      // USER UUID Decoder
      let uuid_decoder = {
        use maybe_uuid <- decode.then(decode.string)
        case uuid.from_string(maybe_uuid) {
          Error(_) -> decode.failure(uuid.v7(), "uuid")
          Ok(value) -> decode.success(value)
        }
      }

      // USER ROLE DECODER
      let user_role_decoder = {
        use maybe_role <- decode.then(decode.string)
        case role.from_string_pt_br(maybe_role) {
          Error(_) -> decode.failure(role.Firefighter, "user_role")
          Ok(value) -> decode.success(value)
        }
      }

      use user_uuid <- decode.field("id", uuid_decoder)
      use full_name <- decode.field("full_name", decode.string)
      use email <- decode.field("email", decode.string)
      use user_role <- decode.field("user_role", user_role_decoder)
      use registration <- decode.field("registration", decode.string)
      use is_active <- decode.field("is_active", decode.bool)

      //   ASSERT
      assert user_uuid == dummy_user_id as "Wrong user uudid"
      assert full_name == new_full_name as "Wrong user name"
      assert email == new_email as "Wrong user email"
      assert user_role == new_role as "Wrong user role"
      assert is_active == new_status as "Wrong user status"
      assert registration == new_registration as "Wrong user registration"

      decode.success(Nil)
    })

  // 󰃢  CLEANUP ----------------------------------------------------------------
  let assert Ok(deleted_user) = {
    let assert Ok(returned) = u_sql.delete_user_by_id(ctx.db, dummy_user_id)
      as "Failed to delete dummy user"
    list.first(returned.rows)
  }
    as "Missing deletion confirmation"

  assert deleted_user.id == dummy_user_id as "Deleted the wrong user"
}

pub fn update_user_status_test() {
  let ctx = app_test.global_data()
  use _ <- list.each(list.range(1, app_test.n_tests))

  let dummy_user = dummy.random_user(ctx.db)
  let path = "/admin/users/" <> uuid.to_string(dummy_user) <> "/status"

  let target_status = False

  let req =
    simulate.request(http.Put, path)
    |> simulate.json_body(json.object([#("status", json.bool(target_status))]))

  let resp = router.handle_request(req, ctx)

  assert resp.status == 401 as "Only accessible to Admin users"

  let req = app_test.with_authorization(req)
  let resp = router.handle_request(req, ctx)

  assert resp.status == 200 as "Status should be 200"
  let body = simulate.read_body(resp)

  let assert Ok(_) =
    json.parse(body, {
      use id <- decode.field("id", decode.string)
      use is_active <- decode.field("is_active", decode.bool)

      assert id == uuid.to_string(dummy_user) as "Incorrect field value"
      assert is_active == target_status as "Incorrect field value"

      decode.success(Nil)
    })

  let assert Ok(_) = dev_sql.soft_truncate_user_account(ctx.db)
}
