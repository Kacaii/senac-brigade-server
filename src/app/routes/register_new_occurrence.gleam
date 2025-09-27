import app/web.{type Context}
import formal/form
import wisp
import youid/uuid

pub opaque type Occurrence {
  Occurrence(
    applicant_id: String,
    category_id: String,
    subcategory_id: String,
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
  )
}

// 󱐀  A form that decodes the `Occurrence` type
fn occurence_form() -> form.Form(Occurrence) {
  form.new({
    use applicant_id <- form.field(todo as "form value", {
      form.parse_string
      |> form.check_not_empty()
    })
    use category_id <- form.field(todo as "form value", {
      form.parse_string
      |> form.check_not_empty()
    })
    use subcategory_id <- form.field(todo as "form value", { form.parse_string })
    use description <- form.field(todo as "form value", { form.parse_string })
    use location <- form.field(todo as "form value", {
      form.parse_list(form.parse_float)
    })
    use reference_point <- form.field(todo as "form value", {
      form.parse_string
    })
    use vehicle_code <- form.field(todo as "form_value", form.parse_string)

    form.success(Occurrence(
      applicant_id:,
      category_id:,
      subcategory_id:,
      description:,
      location:,
      reference_point:,
      vehicle_code:,
    ))
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

  todo as "handle request"
}
