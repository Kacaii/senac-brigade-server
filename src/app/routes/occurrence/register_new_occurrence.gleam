//// Processes occurrence registration form data, validates inputs, and creates
//// a new occurrence record in the database.

import app/routes/occurrence.{type Occurrence, Occurrence}
import app/routes/occurrence/sql
import app/web.{type Context}
import formal/form
import gleam/list
import gleam/result
import gleam/string
import pog
import wisp
import youid/uuid

const cookie_user_id = "USER_ID"

/// 󰞏  Handles occurrence registration form submission by validating form data,
/// creating an occurrence record, and inserting it into the database with
/// appropriate error responses.
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
    Error(_) -> wisp.bad_request("Formulário Inválido")
    Ok(form_data) -> handle_form(request:, ctx:, form_data:)
  }
}

/// Validates and constructs an Occurrence from form data by converting string
/// IDs to UUIDs and extracting the applicant ID from request cookies.
fn insert_occurrence(
  request request: wisp.Request,
  form_data data: OccurrenceFormData,
) -> Result(Occurrence, RegisterNewOccurrenceError) {
  use category_id <- result.try(
    uuid.from_string(data.category_id)
    |> result.replace_error(InvalidCategoryUUID(data.category_id)),
  )
  use subcategory_id <- result.try(
    uuid.from_string(data.subcategory_id)
    |> result.replace_error(InvalidSubCategoryUUID(data.subcategory_id)),
  )

  use participants_id <- result.try({
    use id_string <- list.try_map(data.participants_id)
    uuid.from_string(id_string)
    |> result.replace_error(InvalidApplicantUUID(id_string))
  })

  use applicant_id <- result.try(query_user_by_id(request))

  Ok(Occurrence(
    applicant_id:,
    category_id:,
    subcategory_id:,
    description: data.description,
    location: data.location,
    reference_point: data.reference_point,
    vehicle_code: data.vehicle_code,
    participants_id:,
  ))
}

/// Raw form data submitted for creating an occurrence, with all IDs as strings
pub opaque type OccurrenceFormData {
  OccurrenceFormData(
    category_id: String,
    subcategory_id: String,
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
    participants_id: List(String),
  )
}

/// Extracts and validates the user ID from a signed cookie in the request,
/// returning it as a UUID.
fn query_user_by_id(
  request: wisp.Request,
) -> Result(uuid.Uuid, RegisterNewOccurrenceError) {
  use user_id_string <- result.try(
    wisp.get_cookie(request:, name: cookie_user_id, security: wisp.Signed)
    |> result.replace_error(MissingCookie),
  )

  use user_uuid <- result.try(
    uuid.from_string(user_id_string)
    |> result.replace_error(InvalidApplicantUUID(user_id_string)),
  )

  Ok(user_uuid)
}

/// 󱐀  A form that decodes the `Occurrence` type
fn occurence_form() -> form.Form(OccurrenceFormData) {
  form.new({
    use category_id <- form.field("categoria", {
      form.parse_string
      |> form.check_not_empty
    })
    use subcategory_id <- form.field("subcategoria", { form.parse_string })
    use description <- form.field("descricao", { form.parse_string })
    use location <- form.field("localizacao", {
      form.parse_list(form.parse_float)
    })
    use reference_point <- form.field("pontoReferencia", { form.parse_string })
    use vehicle_code <- form.field("codigoViatura", {
      form.parse_string |> form.check_not_empty
    })

    use participants_id <- form.field("participantes", {
      form.parse_list(form.parse_string)
    })

    form.success(OccurrenceFormData(
      category_id:,
      subcategory_id:,
      description:,
      location:,
      reference_point:,
      vehicle_code:,
      participants_id:,
    ))
  })
}

fn handle_form(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data form_data: OccurrenceFormData,
) -> wisp.Response {
  case insert_occurrence(form_data:, request:) {
    Error(err) -> handle_occurrence_error(err)

    Ok(occurrence) -> {
      let insert_result =
        sql.insert_new_occurence(
          ctx.conn,
          occurrence.applicant_id,
          occurrence.category_id,
          occurrence.subcategory_id,
          occurrence.description,
          occurrence.location,
          occurrence.reference_point,
          occurrence.vehicle_code,
          occurrence.participants_id,
        )

      case insert_result {
        Ok(_) ->
          wisp.created()
          |> wisp.set_body(wisp.Text("Ocorrência registrada com sucesso"))
        Error(err) -> handle_database_error(err)
      }
    }
  }
}

fn handle_database_error(err: pog.QueryError) -> wisp.Response {
  case err {
    pog.ConnectionUnavailable -> {
      let body =
        "Conexão com o Banco de Dados não disponível"
        |> wisp.Text

      wisp.internal_server_error()
      |> wisp.set_body(body)
    }
    pog.QueryTimeout -> {
      let body =
        "O Banco de Dados demorou muito para responder"
        |> wisp.Text

      wisp.internal_server_error()
      |> wisp.set_body(body)
    }
    pog.ConstraintViolated(message:, constraint:, detail:) -> {
      let body =
        "
                      🐘  O Banco de Dados apresentou um erro

                      Constraint: {{constraint}}
                      Mensagem:   {{message}}
                      Detalhe:    {{detail}}
                      "
        |> string.replace("{{constraint}}", constraint)
        |> string.replace("{{message}}", message)
        |> string.replace("{{detail}}", detail)
        |> wisp.Text

      wisp.internal_server_error()
      |> wisp.set_body(body)
    }

    _ ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "Ocorreu um erro ao registrar a ocorrência no Banco de Dados",
      ))
  }
}

fn handle_occurrence_error(err: RegisterNewOccurrenceError) -> wisp.Response {
  case err {
    InvalidApplicantUUID(id) ->
      wisp.bad_request("ID de usuário inválido: " <> id)
    InvalidCategoryUUID(id) ->
      wisp.bad_request("ID de categoria inválido: " <> id)
    InvalidSubCategoryUUID(id) ->
      wisp.bad_request("ID de subcategoria inválido: " <> id)
    MissingCookie -> wisp.bad_request("Cookie Ausente")
  }
}

/// Represents possible errors that can occur during occurrence registration,
/// including invalid UUID formats for applicant, category, or subcategory,
/// and missing authentication cookie.
type RegisterNewOccurrenceError {
  /// The provided applicant ID is not a valid UUID format
  InvalidApplicantUUID(String)
  /// The provided category ID is not a valid UUID format
  InvalidCategoryUUID(String)
  /// The provided subcategory ID is not a valid UUID format
  InvalidSubCategoryUUID(String)
  /// The required user authentication cookie is missing from the request
  MissingCookie
}
