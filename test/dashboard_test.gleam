import app/router
import app_test
import gleam/dynamic/decode
import gleam/http
import gleam/json
import wisp/simulate

pub fn dashboard_stats_test() {
  let ctx = app_test.global_data()

  let req = simulate.browser_request(http.Get, "/dashboard/stats")
  let resp = router.handle_request(req, ctx)
  assert resp.status == 200 as "Response status should be 200"

  let body = simulate.read_body(resp)
  let assert Ok(_) =
    json.parse(body, {
      use _ <- decode.field("totalOcorrencias", decode.int)
      use _ <- decode.field("ocorrenciasHoje", decode.int)
      use _ <- decode.field("emAndamento", decode.int)
      use _ <- decode.field("equipesAtivas", decode.int)
      decode.success(Nil)
    })
    as "Response should contain valid JSON data"
}
