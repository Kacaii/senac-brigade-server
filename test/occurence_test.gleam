import app/router
import app/routes/brigade/sql as b_sql
import app/routes/occurrence/category
import app/routes/occurrence/priority
import app/routes/occurrence/sql as o_sql
import app/routes/occurrence/subcategory
import app/routes/user/sql as u_sql
import app_test
import dummy
import gleam/dynamic/decode
import gleam/float
import gleam/http
import gleam/json
import gleam/list
import wisp
import wisp/simulate
import youid/uuid

pub fn register_new_occurrence_test() {
  let ctx = app_test.global_data()

  // DUMMY USERS -----------------------------------------------------------
  let dummy_applicant_id = dummy.random_user(ctx)
  let dummy_participants_id = {
    list.map(list.range(0, 12), fn(_) { dummy.random_user(ctx) })
  }

  // DUMMY BRIGADE -------------------------------------------------------------
  let dummy_brigade_id =
    dummy.random_brigade(
      ctx:,
      applicant: dummy_applicant_id,
      participants: dummy_participants_id,
    )

  // REQUEST -------------------------------------------------------------------
  let oc_category = category.to_string(dummy.random_category())
  let oc_subcategory = subcategory.to_string(dummy.random_subcategory())
  let oc_priority = priority.to_string(dummy.random_priority())
  let coords = [float.random() *. 100.0, float.random() *. 100.0]

  let req =
    simulate.browser_request(http.Post, "/occurrence/new")
    |> simulate.json_body(
      json.object([
        #("categoria", json.string(oc_category)),
        #("subcategoria", json.string(oc_subcategory)),
        #("prioridade", json.string(oc_priority)),
        #("descricao", json.string(wisp.random_string(33))),
        #("gps", json.array(coords, json.float)),
        #("codigoViatura", json.string(wisp.random_string(6))),
        #("pontoDeReferencia", json.string(wisp.random_string(33))),
        #("idEquipe", json.string(uuid.to_string(dummy_brigade_id))),
      ]),
    )

  // RESPONSE ------------------------------------------------------------------
  let resp = router.handle_request(req, ctx)
  assert resp.status == 401
    as "Endpoint should only accessible to authenticated users"

  let with_auth = app_test.with_authorization(next: req)
  let resp = router.handle_request(with_auth, ctx)
  assert resp.status == 201 as "Status should be HTTP 201 Created"

  // JSON PARSING --------------------------------------------------------------
  let body = simulate.read_body(resp)
  let assert Ok(dummy_occurrence_id) =
    json.parse(body, {
      // Decoder for UUIDs 
      let uuid_decoder = {
        use maybe_uuid <- decode.then(decode.string)
        case uuid.from_string(maybe_uuid) {
          Error(_) -> decode.failure(uuid.v7(), "id")
          Ok(value) -> decode.success(value)
        }
      }

      // Decoder for Priority
      let priority_decoder = {
        use maybe_priority <- decode.then(decode.string)
        case priority.from_string_pt_br(maybe_priority) {
          Error(_) -> decode.failure(priority.Low, "priority")
          Ok(value) -> decode.success(value)
        }
      }

      use dummy_occurrence_id <- decode.field("id", uuid_decoder)
      use _ <- decode.field("priority", priority_decoder)
      use _ <- decode.optional_field("applicant_id", uuid.v7(), uuid_decoder)
      use _ <- decode.optional_field("brigade_id", uuid.v7(), uuid_decoder)
      use _ <- decode.field("created_at", decode.float)
      decode.success(dummy_occurrence_id)
    })
    as "Response should contain valid JSON"

  // 󰃢  CLEANUP ----------------------------------------------------------------
  let assert Ok(cleanup_occurrence) = {
    let assert Ok(returned) =
      o_sql.delete_occurence_by_id(ctx.conn, dummy_occurrence_id)
      as "Failed to cleanup dummy occurrence"
    list.first(returned.rows)
  }

  let assert Ok(cleanup_brigade) = {
    let assert Ok(returned) =
      b_sql.delete_brigade_by_id(ctx.conn, dummy_brigade_id)
      as "Failed to delete dummy brigade"

    list.first(returned.rows)
  }

  let assert Ok(cleanup_applicant) = {
    let assert Ok(returned) =
      u_sql.delete_user_by_id(ctx.conn, dummy_applicant_id)
      as "Failed to cleanup dummy user"

    list.first(returned.rows)
  }

  let cleanup_participants = {
    use participant <- list.map(dummy_participants_id)
    let assert Ok(returned) = u_sql.delete_user_by_id(ctx.conn, participant)
      as "Failed to delete participant"
    let assert Ok(row) = list.first(returned.rows)
      as "Database returned no results"

    row.id
  }

  assert cleanup_brigade.id == dummy_brigade_id as "Deleted the wrong Brigade"
  assert cleanup_applicant.id == dummy_applicant_id as "Deleted the wrong User"
  assert cleanup_participants == dummy_participants_id
    as "Deleted the wrong Participants"
  assert cleanup_occurrence.id == dummy_occurrence_id
    as "Deleted the wrong Occurrence"
}
