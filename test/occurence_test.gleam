import app/router
import app_test
import gleam/http
import gleam/json
import wisp/simulate
import youid/uuid

pub fn register_new_occurrence_test() {
  let ctx = app_test.global_data()

  let req =
    simulate.browser_request(http.Post, "/occurrence/new")
    |> simulate.form_body([
      #("categoria", "fire"),
      #("subcategoria", "residential"),
      #("prioridade", "low"),
      #("descricao", "Everything is on fire"),
      #("gps", json.to_string(json.array([-100.0, 100.0], json.float))),
      #("codigoViatura", "ABC"),
      #("pontoDeReferencia", "Behind you"),
      #("idEquipe", uuid.v7_string()),
    ])

  let resp = router.handle_request(req, ctx)
  assert resp.status == 401 as "Endpoint only accessible to authenticated users"
}
