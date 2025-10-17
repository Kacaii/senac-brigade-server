//// Processes occurrence registration form data, validates inputs, and creates
//// a new occurrence record in the database.

import app/database
import app/routes/occurrence/category
import app/routes/occurrence/priority
import app/routes/occurrence/sql
import app/routes/occurrence/subcategory
import app/routes/user
import app/web.{type Context}
import formal/form
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
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
///   "date": 1759790156.0,
///   "priority": "medium",
///   "applicant_id": "3292ca76-9582-434c-b572-efc80aa9a730",
///   "brigade_id": "4b3f860f-0dbf-4825-8a31-246d0bd430a8"
/// }
/// ```
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use form_data <- wisp.require_form(request)
  let form_result =
    occurence_form()
    |> form.add_values(form_data.values)
    |> form.run

  case form_result {
    Error(_) -> wisp.unprocessable_content()
    Ok(form_data) -> handle_form_data(request:, ctx:, form_data:)
  }
}

fn handle_form_data(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data form_data: RegisterOccurrenceForm,
) -> wisp.Response {
  case insert_occurrence(request:, ctx:, form_data:) {
    Error(err) -> handle_error(err)
    Ok(data) -> wisp.json_response(json.to_string(data), 201)
  }
}

fn handle_error(err: RegisterNewOccurrenceError) -> wisp.Response {
  case err {
    AuthenticationFailed(err) -> user.handle_authentication_error(err)

    InvalidCategory(unknown) ->
      wisp.bad_request("Categoria inválida: " <> unknown)

    InvalidSubCategory(unknown) ->
      wisp.bad_request("Subcategoria inválida: " <> unknown)

    DataBaseError(err) -> database.handle_database_error(err)

    DataBaseReturnedEmptyRow(_) ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text("O Banco de Dados não retornou resultados"))

    InvalidBrigadeUuid(id) ->
      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text("Equipe possui Uuid inválido: " <> id))

    InvalidOccurrencePriority(unknown) ->
      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text(
        "O ocorrencia possui prioridade inválida: " <> unknown,
      ))

    InvalidLocation(unkwown) ->
      wisp.bad_request(
        "Localização inválida, o formato precisa ser um par de coordenadas: "
        <> unkwown,
      )
  }
}

fn insert_occurrence(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data data: RegisterOccurrenceForm,
) -> Result(json.Json, RegisterNewOccurrenceError) {
  //   User
  use applicant_uuid <- result.try(
    user.auth_user_from_cookie(request:, cookie_name: "USER_ID")
    |> result.map_error(AuthenticationFailed),
  )

  // 
  use occurrence_category <- result.try(
    category.from_string(data.occurrence_category)
    |> result.replace_error(InvalidCategory(data.occurrence_category)),
  )

  // 
  use occurrence_subcategory <- result.try(
    subcategory.from_string(data.occurrence_subcategory)
    |> result.replace_error(InvalidSubCategory(data.occurrence_subcategory)),
  )

  // 
  use brigade_id <- result.try(
    uuid.from_string(data.brigade_id)
    |> result.replace_error(InvalidBrigadeUuid(data.brigade_id)),
  )

  use occurrence_priority <- result.try(
    priority.from_string(data.priority)
    |> result.replace_error(InvalidOccurrencePriority(data.priority)),
  )

  use location <- result.try(
    json.parse(data.location, decode.list(decode.float))
    |> result.replace_error(InvalidLocation(data.location)),
  )

  use returned <- result.try(
    sql.insert_new_occurence(
      ctx.conn,
      applicant_uuid,
      category_to_enum(occurrence_category),
      subcategory_to_enum(occurrence_subcategory),
      occurrence_priority,
      data.description,
      location,
      data.reference_point,
      data.vehicle_code,
      brigade_id,
    )
    |> result.map_error(DataBaseError),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.map_error(DataBaseReturnedEmptyRow),
  )
  // RESPONSE ------------------------------------------------------------------
  json.object([
    #("id", uuid.to_string(row.id) |> json.string),
    #("applicant_id", uuid.to_string(row.id) |> json.string),
    #("priority", json.string(enum_to_string(row.priority))),
    #("brigade_id", uuid.to_string(row.brigade_id) |> json.string),
    #("created_at", json.float(timestamp.to_unix_seconds(row.created_at))),
  ])
}

fn enum_to_string(enum: sql.OccurrencePriorityEnum) {
  case enum {
    sql.High -> "alta"
    sql.Low -> "média"
    sql.Medium -> "baixa"
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

fn occurence_form() -> form.Form(RegisterOccurrenceForm) {
  form.new({
    use occurrence_category <- form.field("categoria", {
      form.parse_string |> form.check_not_empty()
    })
    use occurrence_subcategory <- form.field("subcategoria", {
      form.parse_string
    })
    use priority <- form.field("prioridade", form.parse_string)
    use description <- form.field("descricao", { form.parse_string })
    use location <- form.field("gps", form.parse_string)
    use vehicle_code <- form.field("codigoViatura", { form.parse_string })
    use reference_point <- form.field("pontoDeReferencia", { form.parse_string })
    use brigade_id <- form.field("idEquipe", form.parse_string)

    form.success(RegisterOccurrenceForm(
      occurrence_category:,
      occurrence_subcategory:,
      priority:,
      description:,
      location:,
      reference_point:,
      vehicle_code:,
      brigade_id:,
    ))
  })
}

/// Raw form data submitted for creating an occurrence, with all IDs as strings
pub opaque type RegisterOccurrenceForm {
  RegisterOccurrenceForm(
    occurrence_category: String,
    occurrence_subcategory: String,
    priority: String,
    description: String,
    /// Needs to be json string with an array of floats
    location: String,
    reference_point: String,
    vehicle_code: String,
    brigade_id: String,
  )
}

/// Registering a new occurrence can fail
type RegisterNewOccurrenceError {
  /// Failed to authenticate the user
  AuthenticationFailed(user.AuthenticationError)
  /// Occurrence has an invalid category
  InvalidCategory(String)
  /// Occurrence has an invalid subcategory
  InvalidSubCategory(String)
  /// A participant has an invalid UUID
  InvalidBrigadeUuid(String)
  InvalidOccurrencePriority(String)
  /// Failed to access the database
  DataBaseError(pog.QueryError)
  /// Database returned no results
  DataBaseReturnedEmptyRow(Nil)
  InvalidLocation(String)
}
