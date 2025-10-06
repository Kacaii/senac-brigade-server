//// Processes occurrence registration form data, validates inputs, and creates
//// a new occurrence record in the database.

import app/routes/occurrence
import app/routes/occurrence/sql
import app/routes/user
import app/web.{type Context}
import formal/form
import gleam/list
import gleam/result
import gleam/string
import wisp
import youid/uuid

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
    Ok(form_data) -> todo
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
    use description <- form.field("descricao", { form.parse_string })
    use location <- form.field("gps", { form.parse_list(form.parse_float) })
    use vehicle_code <- form.field("codigoViatura", { form.parse_string })
    use reference_point <- form.field("pontoDeReferencia", { form.parse_string })
    use participants_id <- form.field("participantes", {
      form.parse_list(form.parse_string)
    })

    form.success(RegisterOccurrenceForm(
      occurrence_category:,
      occurrence_subcategory:,
      description:,
      location:,
      reference_point:,
      vehicle_code:,
      participants_id:,
    ))
  })
}

/// Raw form data submitted for creating an occurrence, with all IDs as strings
pub opaque type RegisterOccurrenceForm {
  RegisterOccurrenceForm(
    occurrence_category: String,
    occurrence_subcategory: String,
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
    participants_id: List(String),
  )
}

/// 󰘨  Validated occurrence data with all `Strings` converted to `UUIDs`,
/// ready for DataBase insertion
/// 󰆺  Validates and constructs an Occurrence from form data by converting string
/// IDs to UUIDs and extracting the applicant ID from request cookies.
fn insert_occurrence(
  request request: wisp.Request,
  form_data data: RegisterOccurrenceForm,
) -> Result(RegisterOccurrenceForm, RegisterNewOccurrenceError) {
  todo
}

type RegisterNewOccurrenceError
