import app/router
import app/routes/role
import app_test
import dummy
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/set
import wisp/simulate
import youid/uuid

pub fn get_brigade_members_test() {
  let ctx = app_test.global_data()

  // 󰚩  DUMMY ------------------------------------------------------------------
  let leader_id = dummy.random_user(ctx)

  // 󰚩  DUMMY MEMBERS ----------------------------------------------------------
  let dummy_members =
    list.map(list.range(0, 9), fn(_) { dummy.random_user(ctx) })

  // 󰚩  󰚩  󰚩  DUMMY BRIGADE ----------------------------------------------------
  let dummy_brigade =
    dummy.random_brigade(ctx:, leader_id:, participants: dummy_members)

  // START ---------------------------------------------------------------------

  let path = "/brigade/" <> uuid.to_string(dummy_brigade) <> "/members"
  let req = simulate.browser_request(http.Get, path)

  let resp = router.handle_request(req, ctx)
  assert resp.status == 200 as "Response should be HTTP 200 OK"

  let body = simulate.read_body(resp)
  let assert Ok(members_list) =
    json.parse(body, {
      // UUID DECODER
      let uuid_decoder = {
        use maybe_id <- decode.then(decode.string)
        case uuid.from_string(maybe_id) {
          Error(_) -> decode.failure(uuid.v7(), "user_uuid")
          Ok(value) -> decode.success(value)
        }
      }

      // ROLE DECODER
      let role_decoder = {
        use maybe_role <- decode.then(decode.string)
        case role.from_string_pt_br(maybe_role) {
          Error(_) -> decode.failure(role.Firefighter, "user_role")
          Ok(value) -> decode.success(value)
        }
      }

      // DECODER
      decode.list({
        use user_uuid <- decode.field("id", uuid_decoder)
        use _ <- decode.field("full_name", decode.string)
        use _ <- decode.field("user_role", role_decoder)
        decode.success(user_uuid)
      })
    })

  let returned_members_set = set.from_list(members_list)
  let dummy_members_set = set.from_list(dummy_members)

  assert set.difference(returned_members_set, dummy_members_set)
    |> set.to_list()
    == []
    as "Returned list should be the same as the members list"

  // 󰃢  CLEANUP ---------------------------------------------------------------- 
  dummy.clean_user(ctx, leader_id)
  dummy.clean_user_list(ctx, dummy_members)
  dummy.clean_brigade(ctx, dummy_brigade)
}
