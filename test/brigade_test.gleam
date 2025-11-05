import app/router
import app/routes/role
import app_dev/sql as dev_sql
import app_test
import dummy
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/set
import wisp
import wisp/simulate
import youid/uuid

pub fn register_new_brigade() {
  let path = "/admin/teams"
  let ctx = app_test.global_data()
  use _ <- list.each(list.range(1, app_test.n_tests))

  // 󰚩  DUMMY ------------------------------------------------------------------
  let dummy_leader = dummy.random_user(ctx.conn)
  let dummy_members =
    list.map(list.range(1, 10), fn(_) { dummy.random_user(ctx.conn) })
  let dummy_members_json =
    json.array(dummy_members, fn(member) { json.string(uuid.to_string(member)) })

  // START ---------------------------------------------------------------------

  let req =
    simulate.browser_request(http.Post, path)
    |> simulate.json_body(
      json.object([
        #("liderId", json.string(uuid.to_string(dummy_leader))),
        #("nome", json.string(wisp.random_string(6))),
        #("codigoViatura", json.string(wisp.random_string(6))),
        #("ativo", json.bool(True)),
        #("membros", dummy_members_json),
      ]),
    )

  let resp = router.handle_request(req, ctx)
  assert resp.status == 401 as "Endpoint restricted to Admin users"

  let body = simulate.read_body(resp)
  let assert Ok(_) =
    json.parse(body, {
      let uuid_decoder = {
        use maybe_uuid <- decode.then(decode.string)
        case uuid.from_string(maybe_uuid) {
          Error(_) -> decode.failure(uuid.v7(), "uuid")
          Ok(value) -> decode.success(value)
        }
      }

      let members_decoder = {
        use members <- decode.then(decode.list(of: uuid_decoder))
        decode.success(members)
      }

      use leader_id <- decode.field("lider", uuid_decoder)
      use members <- decode.field("members", members_decoder)
      use _ <- decode.field("created_at", decode.float)

      let members_set = set.from_list(members)
      let dummy_members_set = set.from_list(dummy_members)

      // ASSERTIONS ------------------------------------------------------------
      assert leader_id == dummy_leader as "Wrong leader"

      assert set.difference(members_set, dummy_members_set) |> set.to_list()
        == []
        as "Returned members contain unexpected users"
      assert set.difference(dummy_members_set, members_set) |> set.to_list()
        == []
        as "Some brigade members were not returned"

      decode.success(Nil)
    })

  // 󰃢  CLEANUP ----------------------------------------------------------------
  let assert Ok(_) = dev_sql.soft_truncate_user_account(ctx.conn)
  let assert Ok(_) = dev_sql.truncate_brigade(ctx.conn)
}

pub fn get_brigade_members_test() {
  let ctx = app_test.global_data()
  use _ <- list.each(list.range(1, app_test.n_tests))

  //   DUMMY LEADER -----------------------------------------------------------
  let leader_id = dummy.random_user(ctx.conn)

  // 󰚩  DUMMY MEMBERS ----------------------------------------------------------
  let dummy_members =
    list.map(list.range(1, 10), fn(_) { dummy.random_user(ctx.conn) })

  // 󰚩  󰚩  󰚩  DUMMY BRIGADE ----------------------------------------------------
  let dummy_brigade =
    dummy.random_brigade(conn: ctx.conn, leader_id:, members: dummy_members)

  // START ---------------------------------------------------------------------

  let path = "/brigade/" <> uuid.to_string(dummy_brigade) <> "/members"
  let req = simulate.browser_request(http.Get, path)

  let resp = router.handle_request(req, ctx)
  assert resp.status == 200 as "Response should be HTTP 200 OK"

  let body = simulate.read_body(resp)
  let assert Ok(returned_members_list) =
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

  let returned_members_set = set.from_list(returned_members_list)
  let dummy_members_set = set.from_list(dummy_members)

  assert set.difference(returned_members_set, dummy_members_set)
    |> set.to_list()
    == []
    as "Returned list should be the same as the members list"

  // 󰃢  CLEANUP ----------------------------------------------------------------
  let assert Ok(_) = dev_sql.truncate_brigade(ctx.conn)
  let assert Ok(_) = dev_sql.soft_truncate_user_account(ctx.conn)
}

pub fn get_all_brigades_test() {
  let ctx = app_test.global_data()
  use _ <- list.each(list.range(1, app_test.n_tests))
  let path = "/admin/teams"

  //   DUMMY LEADER -----------------------------------------------------------
  let leader_id = dummy.random_user(ctx.conn)

  // 󰚩  DUMMY MEMBERS ----------------------------------------------------------
  let dummy_members =
    list.map(list.range(1, 10), fn(_) { dummy.random_user(ctx.conn) })

  // 󰚩  󰚩  󰚩  DUMMY BRIGADE ----------------------------------------------------
  let dummy_brigade =
    dummy.random_brigade(conn: ctx.conn, leader_id:, members: dummy_members)

  // START ---------------------------------------------------------------------
  let req = simulate.browser_request(http.Get, path)
  let resp = router.handle_request(req, ctx)

  assert resp.status == 200 as "Enpoint should be accessible"

  let body = simulate.read_body(resp)
  let assert Ok(returned_list) =
    json.parse(
      body,
      decode.list({
        let uuid_decoder = {
          use maybe_uuid <- decode.then(decode.string)
          case uuid.from_string(maybe_uuid) {
            Error(_) -> decode.failure(uuid.v7(), "brigade_uuid")
            Ok(value) -> decode.success(value)
          }
        }

        use brigade_uuid <- decode.field("id", uuid_decoder)
        use _ <- decode.field("brigade_name", decode.string)
        use _ <- decode.optional_field("leader_name", "wibble", decode.string)
        use _ <- decode.field("is_active", decode.bool)
        decode.success(brigade_uuid)
      }),
    )
    as "Response should contain valid JSON"

  assert list.contains(returned_list, dummy_brigade)
    as "Response should contain the dummy brigade"

  // 󰃢  CLEANUP ---------------------------------------------------------------
  let assert Ok(_) = dev_sql.truncate_brigade(ctx.conn)
  let assert Ok(_) = dev_sql.soft_truncate_user_account(ctx.conn)
}
