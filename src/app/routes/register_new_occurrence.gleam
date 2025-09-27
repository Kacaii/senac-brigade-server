import app/web.{type Context}
import formal/form
import gleam/option
import gleam/result
import gleam/string
import wisp
import youid/uuid

// TODO: We need better names.
// Also, should probably parse the UUID's outside the form
pub opaque type Occurrence {
  OccurrenceForm(
    applicant_id: String,
    category_id: String,
    subcategory_id: String,
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
  )
  OccurrenceParsed(
    applicant_id: uuid.Uuid,
    category_id: uuid.Uuid,
    subcategory_id: uuid.Uuid,
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
  )
}

/// 󱐀  A form that decodes the `Occurrence` type
fn occurence_form() -> form.Form(Occurrence) {
  form.new({
    use applicant_id_string <- form.field("responsavel", {
      form.parse_string
      |> form.check_not_empty()
    })
    use category_id_string <- form.field("categoria", {
      form.parse_string
      |> form.check_not_empty()
    })
    use subcategory_string <- form.field("subcategoria", { form.parse_string })
    use description <- form.field("descricao", { form.parse_string })
    use location <- form.field("localizacao", {
      form.parse_list(form.parse_float)
    })
    use reference_point <- form.field("pontoReferencia", { form.parse_string })
    use vehicle_code <- form.field("codigoViatura", form.parse_string)
    todo
  })
}

pub fn handle_form_submission(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use form_data <- wisp.require_form(request)
  let form_result =
    occurence_form()
    |> form.add_values(form_data.values)
    |> form.run

  todo
}

type RegisterNewOccurrenceError {
  InvalidApplicantUUID
  InvalidCategoryUUID
}
