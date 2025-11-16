import app/http_router
import app/domain/occurrence/category
import app/domain/occurrence/priority
import app/domain/occurrence/sql as o_sql
import app/domain/occurrence/subcategory
import app_dev/sql as dev_sql
import app_test
import dummy
import gleam/dynamic/decode
import gleam/float
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import gleam/set
import wisp
import wisp/simulate
import youid/uuid

pub fn register_new_occurrence_test() {
  let ctx = app_test.global_data()
  use _ <- list.each(list.range(1, app_test.n_tests))

  // DUMMY USERS -----------------------------------------------------------
  let dummy_applicant_id = dummy.random_user(ctx.db)
  let dummy_participants_id = {
    list.map(list.range(0, 12), fn(_) { dummy.random_user(ctx.db) })
  }

  // DUMMY BRIGADE -------------------------------------------------------------
  let dummy_brigade_id =
    dummy.random_brigade(
      conn: ctx.db,
      leader_id: dummy_applicant_id,
      members: dummy_participants_id,
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
        #("pontoDeReferencia", json.string(wisp.random_string(33))),
        #(
          "idEquipes",
          json.array([uuid.to_string(dummy_brigade_id)], json.string),
        ),
      ]),
    )

  // RESPONSE ------------------------------------------------------------------
  let resp = http_router.handle_request(req, ctx)
  assert resp.status != 422 as "Invalid request Payload"
  assert resp.status == 401 as "Endpoint restricted to authenticated users"

  let with_auth = app_test.with_authorization(next: req)
  let resp = http_router.handle_request(with_auth, ctx)
  assert resp.status == 201 as "HTTP 201 Created"

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
      use _ <- decode.field("applicant_id", decode.optional(uuid_decoder))
      use _ <- decode.field("assigned_brigades", decode.list(uuid_decoder))
      use _ <- decode.field("created_at", decode.float)

      decode.success(dummy_occurrence_id)
    })
    as "Response contain valid JSON"

  // Check if users were registered as participants ----------------------------
  let dummy_participants_set = set.from_list(dummy_participants_id)

  let registered_participants_set =
    set.from_list({
      let assert Ok(returned) =
        o_sql.query_participants(ctx.db, dummy_occurrence_id)
        as "Query occurrence participants"

      use row <- list.map(returned.rows)
      row.user_id
    })

  assert set.difference(registered_participants_set, dummy_participants_set)
    |> set.to_list()
    == []
    as "Registered members contain all expected users"

  assert set.difference(dummy_participants_set, registered_participants_set)
    |> set.to_list()
    == []
    as "Participants were assigned correclty"

  // 󰃢  CLEANUP ----------------------------------------------------------------
  let assert Ok(_) = dev_sql.truncate_occurrence(ctx.db)
  let assert Ok(_) = dev_sql.truncate_brigade(ctx.db)
  let assert Ok(_) = dev_sql.soft_truncate_user_account(ctx.db)
}

pub fn get_occurrences_by_applicant_test() {
  let ctx = app_test.global_data()
  use _ <- list.each(list.range(1, app_test.n_tests))

  // DUMMY USERS -----------------------------------------------------------
  let dummy_applicant_id = dummy.random_user(ctx.db)
  let dummy_participants_id = {
    list.map(list.range(0, 12), fn(_) { dummy.random_user(ctx.db) })
  }

  // DUMMY BRIGADE -------------------------------------------------------------
  let dummy_brigade_id =
    dummy.random_brigade(
      conn: ctx.db,
      leader_id: dummy_applicant_id,
      members: dummy_participants_id,
    )

  // DUMMY OCCURRENCE ----------------------------------------------------------
  let dummy_occurrence =
    dummy.random_occurrence(ctx.db, dummy_applicant_id, [dummy_brigade_id])

  let path = "/user/" <> uuid.to_string(dummy_applicant_id) <> "/occurrences"
  let req = simulate.browser_request(http.Get, path)

  let resp = http_router.handle_request(req, ctx)
  let body = simulate.read_body(resp)
  assert resp.status == 200

  // JSON PARSING --------------------------------------------------------------
  let assert Ok(_) =
    json.parse(body, {
      let uuid_decoder = {
        use maybe_uuid <- decode.then(decode.string)
        case uuid.from_string(maybe_uuid) {
          Error(_) -> decode.failure(uuid.v7(), "id")
          Ok(value) -> decode.success(value)
        }
      }

      let priority_decoder = {
        use maybe_priority <- decode.then(decode.string)
        case priority.from_string_pt_br(maybe_priority) {
          Error(_) -> decode.failure(priority.Low, "prioridade")
          Ok(value) -> decode.success(value)
        }
      }

      let call_decoder = {
        use _ <- decode.field("tipo", category.decoder_pt_br())
        use _ <- decode.field("detalhes", decode.string)
        use _ <- decode.field("solicitante", {
          use name <- decode.field("nome", decode.string)
          decode.success(name)
        })
        decode.success(Nil)
      }

      let occurrence_timestamp_decoder = {
        use _ <- decode.field("abertura", decode.float)
        use _ <- decode.field("chegadaNoLocal", decode.optional(decode.float))
        use _ <- decode.field("finalizacao", decode.optional(decode.float))
        decode.success(Nil)
      }

      let occurrence_metadata_decoder = {
        use _ <- decode.field("usuarioId", uuid_decoder)
        use _ <- decode.field("matriculaUsuario", decode.string)
        use _ <- decode.field("nomeUsuario", decode.string)
        decode.success(Nil)
      }

      let occurrence_brigade_decoder = {
        use _ <- decode.field("id", uuid_decoder)
        use _ <- decode.field("nomeEquipe", decode.string)
        use _ <- decode.field("codigoViatura", decode.string)
        use _ <- decode.field("lider", decode.string)
        decode.success(Nil)
      }

      decode.list({
        use id <- decode.field("id", uuid_decoder)
        use _ <- decode.field("status", decode.string)
        use _ <- decode.field("prioridade", priority_decoder)
        use _ <- decode.field("chamado", call_decoder)
        use _ <- decode.field(
          "coordenadas",
          decode.optional(decode.list(decode.float)),
        )
        use _ <- decode.field("timestamps", occurrence_timestamp_decoder)
        use _ <- decode.field("metadata", occurrence_metadata_decoder)
        use _ <- decode.field(
          "equipes",
          decode.list(occurrence_brigade_decoder),
        )

        assert id == dummy_occurrence
          as "Occurence uuid should be the same as the dummy one"

        decode.success(Nil)
      })
    })

  // 󰃢  CLEANUP ----------------------------------------------------------------
  let assert Ok(_) = dev_sql.truncate_occurrence(ctx.db)
  let assert Ok(_) = dev_sql.truncate_brigade(ctx.db)
  let assert Ok(_) = dev_sql.soft_truncate_user_account(ctx.db)
}

pub fn delete_occurrence_test() {
  let ctx = app_test.global_data()
  use _ <- list.each(list.range(1, app_test.n_tests))

  // DUMMY
  let dummy_applicant = dummy.random_user(ctx.db)
  let dummy_occurrence =
    dummy.random_occurrence(ctx.db, applicant_id: dummy_applicant, assign: [])

  let path = "/occurrence/" <> uuid.to_string(dummy_occurrence)
  let req = simulate.request(http.Delete, path)
  let resp = http_router.handle_request(req, ctx)

  assert resp.status == 401 as "Only accessible to Admins"

  let with_auth = app_test.with_authorization(req)
  let resp = http_router.handle_request(with_auth, ctx)

  assert resp.status == 200 as "Status should be HTTP 200 OK"

  let body = simulate.read_body(resp)
  let assert Ok(deleted_occurrence) =
    json.parse(body, {
      let uuid_decoder = {
        use maybe_uuid <- decode.then(decode.string)
        case uuid.from_string(maybe_uuid) {
          Error(_) -> decode.failure(uuid.v7(), "occurrence_uuid")
          Ok(value) -> decode.success(value)
        }
      }

      use id <- decode.field("id", uuid_decoder)
      decode.success(id)
    })

  assert deleted_occurrence == dummy_occurrence
    as "Deleted the wrong Occurrence"

  // 󰃢  CLEANUP ----------------------------------------------------------------
  let assert Ok(_) = dev_sql.soft_truncate_user_account(ctx.db)
}

pub fn resolve_occurrence_test() {
  let ctx = app_test.global_data()
  let base_path = "/occurrence/resolved_at/"
  use _ <- list.each(list.range(1, app_test.n_tests))

  // DUMMY ---------------------------------------------------------------------
  let dummy_applicant = dummy.random_user(ctx.db)
  let dummy_members =
    list.map(list.range(1, 10), fn(_) { dummy.random_user(ctx.db) })

  let dummy_brigade =
    dummy.random_brigade(ctx.db, dummy_applicant, dummy_members)

  let dummy_occurrence =
    dummy.random_occurrence(
      conn: ctx.db,
      applicant_id: dummy_applicant,
      assign: [dummy_brigade],
    )

  let path = base_path <> uuid.to_string(dummy_occurrence)
  let req = simulate.request(http.Post, path)
  let resp = http_router.handle_request(req, ctx)

  assert resp.status == 401 as "Restricted to authenticated Users"

  // Response decoder
  let resp_decoder = {
    let uuid_decoder = {
      use maybe_uuid <- decode.then(decode.string)
      case uuid.from_string(maybe_uuid) {
        Error(_) -> decode.failure(uuid.v7(), "occurrence_uuid")
        Ok(value) -> decode.success(value)
      }
    }

    let resolved_at_decoder = decode.optional(decode.float)

    use occ_id <- decode.field("id", uuid_decoder)
    use resolved_at <- decode.field("resolved_at", resolved_at_decoder)
    use _ <- decode.field("updated_at", decode.float)

    assert option.is_some(resolved_at) as "Occurrence should be closed"
    assert occ_id == dummy_occurrence as "Update the correct occurrence"
    decode.success(Nil)
  }

  let _happy_path = {
    let req = app_test.with_authorization(req)
    let resp = http_router.handle_request(req, ctx)
    let body = simulate.read_body(resp)

    let assert Ok(_) = json.parse(body, resp_decoder)
      as "Json response should be valid"
  }

  // 󰃢  CLEANUP ----------------------------------------------------------------
  let assert Ok(_) = dev_sql.truncate_occurrence(ctx.db)
  let assert Ok(_) = dev_sql.truncate_brigade(ctx.db)
  let assert Ok(_) = dev_sql.soft_truncate_user_account(ctx.db)
}

pub fn resolve_missing_occurrence_test() {
  let ctx = app_test.global_data()
  let base_path = "/occurrence/resolved_at/"
  let path = base_path <> uuid.v7_string()

  let req =
    simulate.browser_request(http.Post, path)
    |> app_test.with_authorization()

  let resp = http_router.handle_request(req, ctx)
  assert resp.status == 404 as "Cant resolve missing occurrence"
}

pub fn reopen_occurrence_test() {
  let ctx = app_test.global_data()
  let base_path = "/occurrence/resolved_at/"
  use _ <- list.each(list.range(1, app_test.n_tests))

  // DUMMY ---------------------------------------------------------------------
  let dummy_applicant = dummy.random_user(ctx.db)
  let dummy_members =
    list.map(list.range(1, 10), fn(_) { dummy.random_user(ctx.db) })

  let dummy_brigade =
    dummy.random_brigade(ctx.db, dummy_applicant, dummy_members)

  let dummy_occurrence =
    dummy.random_occurrence(
      conn: ctx.db,
      applicant_id: dummy_applicant,
      assign: [dummy_brigade],
    )

  let path = base_path <> uuid.to_string(dummy_occurrence)
  let req = simulate.request(http.Delete, path)
  let resp = http_router.handle_request(req, ctx)

  assert resp.status == 401 as "Restricted to authenticated Users"
  let req = app_test.with_authorization(req)
  let resp = http_router.handle_request(req, ctx)
  let body = simulate.read_body(resp)

  let assert Ok(_) =
    json.parse(body, {
      let uuid_decoder = {
        use maybe_uuid <- decode.then(decode.string)
        case uuid.from_string(maybe_uuid) {
          Error(_) -> decode.failure(uuid.v7(), "occurrence_uuid")
          Ok(value) -> decode.success(value)
        }
      }

      let resolved_at_decoder = decode.optional(decode.float)

      // PARSE
      use occ_id <- decode.field("id", uuid_decoder)
      use resolved_at <- decode.field("resolved_at", resolved_at_decoder)
      use _ <- decode.field("updated_at", decode.float)

      // ASSERT
      assert option.is_none(resolved_at) as "Occurrence should be open"
      assert occ_id == dummy_occurrence as "Update the correct occurrence"
      decode.success(Nil)
    })

  // 󰃢  CLEANUP ----------------------------------------------------------------
  let assert Ok(_) = dev_sql.truncate_occurrence(ctx.db)
  let assert Ok(_) = dev_sql.truncate_brigade(ctx.db)
  let assert Ok(_) = dev_sql.soft_truncate_user_account(ctx.db)
}

pub fn reopen_missing_occurrence_test() {
  let ctx = app_test.global_data()
  let base_path = "/occurrence/resolved_at/"
  let path = base_path <> uuid.v7_string()

  let req =
    simulate.browser_request(http.Delete, path)
    |> app_test.with_authorization()

  let resp = http_router.handle_request(req, ctx)
  assert resp.status == 404 as "Cant reopen missing occurrence"
}
