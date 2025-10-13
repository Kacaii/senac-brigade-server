import app/routes/role
import app/routes/role/get_role_list
import app_test.{global_data}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import wisp/simulate

pub fn get_role_list_test() {
  let ctx = global_data()

  let req = simulate.browser_request(http.Get, "/api/roles")
  let resp = get_role_list.handle_request(req, ctx)

  assert resp.status == 200 as "Status code should be 200 OK"
  let body = simulate.read_body(resp)

  let assert Ok(parsed_body) = json.parse(body, decode.list(decode.string))
    as "Response body should contain valid JSON"

  assert parsed_body != [] as "Role list should not be empty"

  let assert Ok(_) = list.try_each(parsed_body, role.from_string_pt_br)
    as "Reponse body should contain valid user role types"
}
