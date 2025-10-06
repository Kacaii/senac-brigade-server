//// Processes occurrence registration form data, validates inputs, and creates
//// a new occurrence record in the database.

import app/routes/occurrence/category
import app/routes/occurrence/sql
import app/routes/user
import app/web.{type Context}
import formal/form
import gleam/json
import gleam/list
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
///   "message": "Ocorrência registrada com sucesso",
///   "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
///   "date": 1759790156.0
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
    Error(_) -> wisp.bad_request("Formulário Inválido")
    Ok(form_data) -> handle_form_data(request:, ctx:, form_data:)
  }
}

fn handle_form_data(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data form_data: RegisterOccurrenceForm,
) -> wisp.Response {
  case insert_occurrence(request:, ctx:, form_data:) {
    Ok(returned) -> {
      let resp = {
        json.object([
          #("message", json.string("Ocorrência registrada com sucesso")),
          #("id", json.string(uuid.to_string(returned.id))),
          #("date", json.float(timestamp.to_unix_seconds(returned.created_at))),
        ])
      }

      //   All done!
      wisp.json_response(json.to_string(resp), 201)
    }
    Error(err) ->
      case err {
        AuthenticationFailed(err) -> user.handle_authentication_error(err)

        InvalidCategory(unknown) ->
          wisp.bad_request("Categoria inválida: " <> unknown)
        InvalidSubCategory(unknown) ->
          wisp.bad_request("Subcategoria inválida: " <> unknown)

        InvalidParticipantUUID(participant_id) ->
          wisp.response(401)
          |> wisp.set_body(wisp.Text(
            "ID de participante inválido:" <> participant_id,
          ))

        DataBaseError(err) ->
          case err {
            pog.ConnectionUnavailable ->
              wisp.internal_server_error()
              |> wisp.set_body(wisp.Text(
                "Conexão com o Banco de Dados não disponível",
              ))

            pog.ConstraintViolated(message:, constraint:, detail:) -> {
              wisp.bad_request(
                "
              Uma restrição foi encontrada no Banco de Dados: {{constraint}}
              Mensagem: {{message}}
              Detalhes: {{detail}}"
                |> string.replace("{{constraint}}", constraint)
                |> string.replace("{{message}}", message)
                |> string.replace("{{detail}}", detail),
              )
            }
            pog.QueryTimeout ->
              wisp.internal_server_error()
              |> wisp.set_body(wisp.Text(
                "O Banco de Dados demorou muito para responder",
              ))

            _ ->
              wisp.internal_server_error()
              |> wisp.set_body(wisp.Text(
                "Ocorreu um erro ao acessar o Banco de Dados",
              ))
          }

        DataBaseReturnedEmptyRow(_) ->
          wisp.internal_server_error()
          |> wisp.set_body(wisp.Text("O Banco de Dados não retornou resultados"))
      }
  }
}

fn insert_occurrence(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data data: RegisterOccurrenceForm,
) -> Result(sql.InsertNewOccurenceRow, RegisterNewOccurrenceError) {
  //   User
  use applicant_uuid <- result.try(
    user.auth_user_from_cookie(request:, cookie_name: "USER_ID")
    |> result.map_error(AuthenticationFailed),
  )

  // 
  use form_category <- result.try(
    category.main_category_from_string(data.occurrence_category)
    |> result.replace_error(InvalidCategory(data.occurrence_category)),
  )

  // 
  use form_subcategory <- result.try(
    category.sub_category_from_string(data.occurrence_subcategory)
    |> result.replace_error(InvalidSubCategory(data.occurrence_subcategory)),
  )

  use participants_id_list <- result.try(
    list.try_map(data.participants_id, fn(participant) {
      uuid.from_string(participant)
      |> result.replace_error(InvalidParticipantUUID(participant))
    }),
  )

  use returned <- result.try(
    sql.insert_new_occurence(
      ctx.conn,
      applicant_uuid,
      form_category,
      form_subcategory,
      data.description,
      data.location,
      data.reference_point,
      data.vehicle_code,
      participants_id_list,
    )
    |> result.map_error(DataBaseError),
  )

  // Get the first row
  list.first(returned.rows)
  |> result.map_error(DataBaseReturnedEmptyRow)
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

type RegisterNewOccurrenceError {
  AuthenticationFailed(user.AuthenticationError)
  InvalidCategory(String)
  InvalidSubCategory(String)
  InvalidParticipantUUID(String)
  DataBaseError(pog.QueryError)
  DataBaseReturnedEmptyRow(Nil)
}
