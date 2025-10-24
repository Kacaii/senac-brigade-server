import app/database
import app/routes/brigade/sql
import app/routes/role
import app/routes/user
import app/web.{type Context}
import formal/form
import gleam/json
import gleam/list
import gleam/result
import gleam/time/timestamp
import pog
import wisp
import youid/uuid

///   Insert a new brigade into the database.
/// Performs validation on all the members UUID
/// and return relevant data as formatted JSON response.
///
/// ## Response
///
/// ```json
/// {
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
    register_brigade_form()
    |> form.add_values(form_data.values)
    |> form.run()
  case form_result {
    Ok(form_data) -> handle_form_data(request:, ctx:, form_data:)
    Error(_) ->
      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text("Formulário inválido"))
  }
}

fn handle_form_data(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data form_data: RegisterBrigadeFormData,
) -> wisp.Response {
  case try_register_brigade(request:, ctx:, form_data:) {
    Ok(resp) -> wisp.json_response(json.to_string(resp), 201)
    Error(err) -> handle_error(request:, err:)
  }
}

fn try_register_brigade(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data form_data: RegisterBrigadeFormData,
) -> Result(json.Json, RegisterBrigadeError) {
  use _ <- result.try(
    user.check_role_authorization(
      request:,
      ctx:,
      cookie_name: user.uuid_cookie_name,
      authorized_roles: [role.Admin, role.Developer],
    )
    |> result.map_error(AccessError),
  )

  // Leader of that brigade
  use leader_id <- result.try(
    uuid.from_string(form_data.leader_id)
    |> result.replace_error(InvalidUuid(form_data.leader_id)),
  )

  // Their members
  use members_id <- result.try({
    use maybe_uuid <- list.try_map(form_data.members_id)
    use user_uuid <- result.try(
      uuid.from_string(maybe_uuid)
      |> result.replace_error(InvalidUuid(maybe_uuid)),
    )

    Ok(user_uuid)
  })

  use returned <- result.try(
    sql.insert_new_brigade(
      ctx.conn,
      leader_id,
      form_data.name,
      form_data.vehicle_code,
      members_id,
      form_data.is_active,
    )
    |> result.map_error(DataBaseError),
  )
  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(DataBaseReturnedEmptyRow),
  )

  Ok(
    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("created_at", json.float(timestamp.to_unix_seconds(row.created_at))),
    ]),
  )
}

fn handle_error(request request, err err: RegisterBrigadeError) -> wisp.Response {
  case err {
    DataBaseReturnedEmptyRow ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "O Banco de Dados não retornou informações sobre a nova equipe após a inserção",
      ))
    InvalidUuid(user_id) ->
      wisp.bad_request("Usuário possui UUID inválido: " <> user_id)
    DataBaseError(err) -> database.handle_database_error(err)
    AccessError(err) -> user.handle_authorization_error(request, err)
  }
}

/// 󱐁  Form that decodes the `RegisterBrigadeFormData` type
fn register_brigade_form() -> form.Form(RegisterBrigadeFormData) {
  form.new({
    use leader_id <- form.field("lider_id", {
      form.parse_string |> form.check_not_empty()
    })

    use name <- form.field("nome", {
      form.parse_string |> form.check_not_empty()
    })

    use members_id <- form.field("membros", {
      form.parse_list(form.parse_string)
    })

    use vehicle_code <- form.field(
      "codigoViatura",
      form.parse_string
        |> form.check_not_empty(),
    )
    use is_active <- form.field("ativo", { form.parse_checkbox })

    form.success(RegisterBrigadeFormData(
      leader_id:,
      name:,
      vehicle_code:,
      members_id:,
      is_active:,
    ))
  })
}

type RegisterBrigadeFormData {
  RegisterBrigadeFormData(
    leader_id: String,
    name: String,
    vehicle_code: String,
    members_id: List(String),
    is_active: Bool,
  )
}

type RegisterBrigadeError {
  InvalidUuid(String)
  DataBaseError(pog.QueryError)
  DataBaseReturnedEmptyRow
  AccessError(user.AccessControlError)
}
