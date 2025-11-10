//// Processes occurrence registration form data, validates inputs, and creates
//// a new occurrence record in the database.

import app/routes/occurrence
import app/routes/occurrence/category
import app/routes/occurrence/priority
import app/routes/occurrence/sql
import app/routes/occurrence/subcategory
import app/routes/user
import app/web
import app/web/context.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import gleam/time/timestamp
import group_registry
import pog
import wisp
import youid/uuid

/// 󰞏  Handles occurrence registration form submission by validating form data,
/// creating an occurrence record, and inserting it into the database with
/// appropriate error responses.
///
/// ## Response
///
/// ```json
/// {
///   "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
///   "priority": "medium",
///   "applicant_id": "3292ca76-9582-434c-b572-efc80aa9a730",
///   "created_at": 1759790156.0,
///   "assigned_brigades": [
///     "4b3f860f-0dbf-4825-8a31-246d0bd430a8",
///     "34b5bff8-27a7-45cc-8896-7f791cdb34af",
///     "6a143ea3-1c8c-45e1-9ad9-24a1e19f4892"
///   ]
/// }
/// ```
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Post)
  use body <- wisp.require_json(request)

  // Decode the request's body
  case decode.run(body, body_decoder()) {
    // Handle possible errors
    Error(err) -> web.handle_decode_error(err)
    // Process the parsed data
    Ok(body) -> handle_body(request:, ctx:, body:)
  }
}

fn handle_body(
  request request: wisp.Request,
  ctx ctx: Context,
  body body: RegisterOccurrenceBody,
) -> wisp.Response {
  // Insert the occurrence on the DataBase
  case insert_occurrence(request:, ctx:, body:) {
    //   Handle possible errors
    Error(err) -> handle_error(err)
    //   Send a response to the client 
    Ok(data) -> {
      wisp.json_response(data, 201)
    }
  }
}

/// 󱐁  Form data submitted by the client
pub opaque type RegisterOccurrenceBody {
  RegisterOccurrenceBody(
    ///   Occurrence category
    occurrence_category: category.Category,
    ///   Occurrence subcategory
    occurrence_subcategory: subcategory.Subcategory,
    ///   Occurrence priority
    priority: priority.Priority,
    ///   Description of the occurrence
    description: String,
    ///   Coordenates
    location: List(Float),
    ///   Where the occurrence is located
    reference_point: String,
    ///   All brigades assigned to that occurrence
    brigade_list: List(uuid.Uuid),
  )
}

/// Registering a new occurrence can fail
type RegisterNewOccurrenceError {
  /// Failed to authenticate the user
  AuthenticationFailed(user.AuthenticationError)
  /// Failed to access the database
  DataBaseError(pog.QueryError)
  /// Database returned no results
  OccurrenceNotCreated
  /// Failed to assign a brigade to the giving occurrence
  FailedToAssignBrigade(uuid.Uuid)
}

fn handle_error(err: RegisterNewOccurrenceError) -> wisp.Response {
  case err {
    AuthenticationFailed(err) -> user.handle_authentication_error(err)
    DataBaseError(err) -> web.handle_database_error(err)
    FailedToAssignBrigade(id) ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "Não foi possível designar a equipe: " <> uuid.to_string(id),
      ))
    OccurrenceNotCreated ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text("A ocorrência não foi registrada"))
  }
}

fn body_decoder() {
  let brigade_uuid_decoder = {
    use maybe_uuid <- decode.then(decode.string)
    case uuid.from_string(maybe_uuid) {
      Ok(value) -> decode.success(value)
      Error(_) -> decode.failure(uuid.v7(), "uuid")
    }
  }
  use occ_category <- decode.field("categoria", category.decoder())
  use occ_subcategory <- decode.field("subcategoria", subcategory.decoder())
  use occ_priority <- decode.field("prioridade", priority.decoder())
  use occ_description <- decode.field("descricao", decode.string)
  use occ_location <- decode.field("gps", decode.list(decode.float))
  use occ_reference_point <- decode.field("pontoDeReferencia", decode.string)
  use assigned_brigades_id <- decode.field(
    "idEquipes",
    decode.list(brigade_uuid_decoder),
  )

  decode.success(RegisterOccurrenceBody(
    occurrence_category: occ_category,
    occurrence_subcategory: occ_subcategory,
    priority: occ_priority,
    description: occ_description,
    location: occ_location,
    reference_point: occ_reference_point,
    brigade_list: assigned_brigades_id,
  ))
}

fn insert_occurrence(
  request request: wisp.Request,
  ctx ctx: Context,
  body body: RegisterOccurrenceBody,
) -> Result(String, RegisterNewOccurrenceError) {
  use applicant_uuid <- result.try(
    user.extract_uuid(request:, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AuthenticationFailed),
  )

  use returned <- result.try(
    sql.insert_new_occurence(
      ctx.db,
      applicant_uuid,
      category_to_enum(body.occurrence_category),
      subcategory_to_enum(body.occurrence_subcategory),
      priority_to_enum(body.priority),
      body.description,
      body.location,
      body.reference_point,
    )
    |> result.map_error(DataBaseError),
  )

  use row <- result.try(case list.first(returned.rows) {
    Error(_) -> Error(OccurrenceNotCreated)
    Ok(row) -> Ok(row)
  })

  use assigned_brigades <- result.try(try_assign_brigades(
    ctx:,
    assign: body.brigade_list,
    to: row.id,
  ))

  let assigned_brigades_json =
    json.array(assigned_brigades, fn(assigned) {
      uuid.to_string(assigned) |> json.string
    })

  // RESPONSE ------------------------------------------------------------------
  let occurrence_priority =
    enum_to_priority(row.priority)
    |> priority.to_string_pt_br

  let occ_category = case row.occurrence_category {
    sql.Fire -> category.Fire
    sql.MedicEmergency -> category.MedicEmergency
    sql.Other -> category.Other
    sql.TrafficAccident -> category.TrafficAccident
  }

  //   Broadcast new occurrence
  let registry = group_registry.get_registry(ctx.registry_name)
  occurrence.notify_new_occurrence(new: row.id, of: occ_category, registry:)

  json.object([
    #("id", uuid.to_string(row.id) |> json.string),
    #("applicant_id", uuid.to_string(row.id) |> json.string),
    #("priority", json.string(occurrence_priority)),
    #("assigned_brigades", assigned_brigades_json),
    #("created_at", json.float(timestamp.to_unix_seconds(row.created_at))),
  ])
  |> json.to_string
  |> Ok
}

fn try_assign_brigades(
  ctx ctx: Context,
  assign brigades_id: List(uuid.Uuid),
  to occurrence_id: uuid.Uuid,
) -> Result(List(uuid.Uuid), RegisterNewOccurrenceError) {
  use returned <- result.try(
    sql.assign_brigades_to_occurrence(ctx.db, occurrence_id, brigades_id)
    |> result.map_error(DataBaseError),
  )

  let assigned_brigades = {
    use row <- list.map(returned.rows)
    row.inserted_brigade_id
  }

  use assigned_users <- result.try({
    use returned <- result.try(
      sql.query_participants(ctx.db, occurrence_id)
      |> result.map_error(DataBaseError),
    )

    list.map(returned.rows, fn(row) { row.user_id })
    |> Ok
  })

  //   BROADCAST --------------------------------------------------------------
  let registry = group_registry.get_registry(ctx.registry_name)
  occurrence.broadcast_assignments(
    assigned_users:,
    to: occurrence_id,
    registry:,
  )

  Ok(assigned_brigades)
}

fn priority_to_enum(priority: priority.Priority) -> sql.OccurrencePriorityEnum {
  case priority {
    priority.High -> sql.High
    priority.Low -> sql.Low
    priority.Medium -> sql.Medium
  }
}

fn enum_to_priority(enum: sql.OccurrencePriorityEnum) {
  case enum {
    sql.High -> priority.High
    sql.Medium -> priority.Medium
    sql.Low -> priority.Low
  }
}

fn category_to_enum(category: category.Category) {
  case category {
    category.Fire -> sql.Fire
    category.MedicEmergency -> sql.MedicEmergency
    category.Other -> sql.Other
    category.TrafficAccident -> sql.TrafficAccident
  }
}

fn subcategory_to_enum(subcategory: subcategory.Subcategory) {
  case subcategory {
    subcategory.Collision -> sql.Collision
    subcategory.Comercial -> sql.Comercial
    subcategory.Flood -> sql.Flood
    subcategory.HeartStop -> sql.HeartStop
    subcategory.InjuredAnimal -> sql.InjuredAnimal
    subcategory.Intoxication -> sql.Intoxication
    subcategory.MotorcycleCrash -> sql.MotorcycleCrash
    subcategory.PreHospitalCare -> sql.PreHospitalCare
    subcategory.Residential -> sql.Residential
    subcategory.Rollover -> sql.Rollover
    subcategory.RunOver -> sql.RunOver
    subcategory.Seizure -> sql.Seizure
    subcategory.SeriousInjury -> sql.SeriousInjury
    subcategory.TreeCrash -> sql.TreeCrash
    subcategory.Vegetation -> sql.Vegetation
    subcategory.Vehicle -> sql.Vehicle
  }
}
