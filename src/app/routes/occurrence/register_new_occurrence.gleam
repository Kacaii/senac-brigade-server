//// Processes occurrence registration form data, validates inputs, and creates
//// a new occurrence record in the database.

import app/database
import app/routes/occurrence/category
import app/routes/occurrence/priority
import app/routes/occurrence/sql
import app/routes/occurrence/subcategory
import app/routes/user
import app/web.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp
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
///   "brigade_id": "4b3f860f-0dbf-4825-8a31-246d0bd430a8"
///   "created_at": 1759790156.0,
/// }
/// ```
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Post)

  use body <- wisp.require_json(request)
  let decode_result = decode.run(body, body_decoder())

  case decode_result {
    Ok(data) -> handle_body(request:, ctx:, data:)
    Error(err) -> handle_decode_error(err)
  }
}

fn handle_decode_error(err: List(decode.DecodeError)) -> wisp.Response {
  case err {
    [] -> wisp.ok()
    [err, ..] ->
      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text(
        "Esperava: "
        <> err.expected
        <> "\nEcontrado: "
        <> err.found
        <> "\nEm: "
        <> string.join(err.path, "/"),
      ))
  }
}

fn body_decoder() {
  use occurence_category <- decode.field("categoria", category.decoder())
  use occurrence_subcategory <- decode.field(
    "subcategoria",
    subcategory.decoder(),
  )
  use priority <- decode.field("prioridade", priority.decoder())
  use description <- decode.field("descricao", decode.string)
  use location <- decode.field("gps", decode.list(decode.float))
  use vehicle_code <- decode.field("codigoViatura", decode.string)
  use reference_point <- decode.field("pontoDeReferencia", decode.string)
  use brigade_id <- decode.field("idEquipe", brigade_uuid_decoder())

  decode.success(RegisterOccurrenceBody(
    occurrence_category: occurence_category,
    occurrence_subcategory: occurrence_subcategory,
    priority: priority,
    description: description,
    location: location,
    reference_point: reference_point,
    vehicle_code: vehicle_code,
    brigade_id: brigade_id,
  ))
}

fn brigade_uuid_decoder() {
  use maybe_uuid <- decode.then(decode.string)
  case uuid.from_string(maybe_uuid) {
    Ok(value) -> decode.success(value)
    Error(_) -> decode.failure(uuid.v7(), "uuid")
  }
}

fn handle_body(
  request request: wisp.Request,
  ctx ctx: Context,
  data data: RegisterOccurrenceBody,
) -> wisp.Response {
  case insert_occurrence(request:, ctx:, data:) {
    Error(err) -> handle_error(err)
    Ok(data) -> wisp.json_response(json.to_string(data), 201)
  }
}

fn handle_error(err: RegisterNewOccurrenceError) -> wisp.Response {
  case err {
    AuthenticationFailed(err) -> user.handle_authentication_error(err)

    DataBaseError(err) -> database.handle_database_error(err)

    DataBaseReturnedEmptyRow(_) ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text("O Banco de Dados não retornou resultados"))
  }
}

fn insert_occurrence(
  request request: wisp.Request,
  ctx ctx: Context,
  data data: RegisterOccurrenceBody,
) -> Result(json.Json, RegisterNewOccurrenceError) {
  //   User
  use applicant_uuid <- result.try(
    user.auth_user_from_cookie(request:, cookie_name: "USER_ID")
    |> result.map_error(AuthenticationFailed),
  )

  use returned <- result.try(
    sql.insert_new_occurence(
      ctx.conn,
      applicant_uuid,
      category_to_enum(data.occurrence_category),
      subcategory_to_enum(data.occurrence_subcategory),
      priority_to_enum(data.priority),
      data.description,
      data.location,
      data.reference_point,
      data.vehicle_code,
      data.brigade_id,
    )
    |> result.map_error(DataBaseError),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.map_error(DataBaseReturnedEmptyRow),
  )
  // RESPONSE ------------------------------------------------------------------
  let brigade_id = option.map(row.brigade_id, uuid.to_string)
  let occurrence_priority =
    enum_to_priority(row.priority) |> priority.to_string_pt_br

  json.object([
    #("id", uuid.to_string(row.id) |> json.string),
    #("applicant_id", uuid.to_string(row.id) |> json.string),
    #("priority", json.string(occurrence_priority)),
    #("brigade_id", json.nullable(brigade_id, json.string)),
    #("created_at", json.float(timestamp.to_unix_seconds(row.created_at))),
  ])
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

/// Raw form data submitted for creating an occurrence, with all IDs as strings
pub opaque type RegisterOccurrenceBody {
  RegisterOccurrenceBody(
    occurrence_category: category.Category,
    occurrence_subcategory: subcategory.Subcategory,
    priority: priority.Priority,
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
    brigade_id: uuid.Uuid,
  )
}

/// Registering a new occurrence can fail
type RegisterNewOccurrenceError {
  /// Failed to authenticate the user
  AuthenticationFailed(user.AuthenticationError)
  /// Failed to access the database
  DataBaseError(pog.QueryError)
  /// Database returned no results
  DataBaseReturnedEmptyRow(Nil)
}
