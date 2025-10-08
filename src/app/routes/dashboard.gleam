import app/routes/dashboard/sql
import app/routes/role
import app/routes/user
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import glight
import pog
import wisp
import youid/uuid

/// 󰡦  Retrieve dashboard stats from the DataBase and returns them
/// as formatted JSON data
///
/// ## Response
///
/// ```json
/// {
///   "totalOcorrencias": 0,
///   "ocorrenciasHoje": 0,
///   "emAndamento": 0,
///   "equipesAtivas": 0
/// }
/// ```
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  case get_dashboard_data(request:, ctx:) {
    Ok(value) -> wisp.json_response(json.to_string(value), 200)
    Error(err) -> handle_error(err)
  }
}

fn get_dashboard_data(
  request request: wisp.Request,
  ctx ctx: Context,
) -> Result(json.Json, GetDashboardStatsError) {
  //   AUTHORIZATION CHECK --------------------------------------------------
  use _ <- result.try(
    user.check_role_authorization(
      request:,
      ctx:,
      cookie_name: "USER_ID",
      authorized_roles: [
        role.Admin,
        role.Analist,
      ],
    )
    |> result.map_error(RoleError),
  )

  //  QUERY THE DATABASE ----------------------------------------------------
  use returned <- result.try(
    sql.query_dashboard_stats(ctx.conn)
    |> result.map_error(DataBaseError),
  )
  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(DataBaseReturnedEmptyRow),
  )

  Ok(get_dashboard_stats_row_to_json(row))
}

fn handle_error(err: GetDashboardStatsError) -> wisp.Response {
  case err {
    // 󱋬  DataBase couldn't find the required information for the dashboard
    //
    DataBaseReturnedEmptyRow -> {
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "O Banco de dados não encontrou os dados solicitados",
      ))
    }

    // 󱘺  DATABASE ERRORS --------------------------------------------------
    DataBaseError(err) -> handle_db_error(err)

    //   PERMISSION DENIED ------------------------------------------------
    RoleError(role_err) -> handle_authorization_error(role_err)
  }
}

/// Handle Authorization related errors
fn handle_authorization_error(role_err: user.AuthorizationError) {
  case role_err {
    user.AuthenticationFailed(auth_err) -> {
      case auth_err {
        //   User didn't have a valid UUID
        //
        user.InvalidUUID(user_id) ->
          wisp.response(401)
          |> wisp.set_body(wisp.Text("ID de usuário inválido: " <> user_id))
        //   USER_ID cookie is required to access this endpoint
        //
        user.MissingCookie ->
          wisp.response(401)
          |> wisp.set_body(wisp.Text("Cookie de autenticação ausente"))
      }
    }
    // 󱏊  Database couldn't find a user role with that UUDI
    //
    user.DataBaseReturnedEmptyRow ->
      wisp.response(401)
      |> wisp.set_body(wisp.Text(
        "Não foi possível identificar o cargo do usuário",
      ))

    //   User is not authorized to access this endpoint -------------------
    //
    user.Unauthorized(user_uuid, user_role) -> {
      //   Log who tried to access and whats their role
      log_unauthorized_access_attempt(user_uuid:, user_role:)
      //   403 FORBIDDEN response
      wisp.response(403)
      |> wisp.set_body(wisp.Text(
        "Usuário não autorizado: "
        <> role.to_string(user_role)
        <> " "
        <> uuid.to_string(user_uuid),
      ))
    }

    //   DATABASE ERRORS ----------------------------------------------
    //
    user.DataBaseError(db_err) -> handle_db_error(db_err)
  }
}

/// Handle DataBase related errors
fn handle_db_error(err: pog.QueryError) {
  let db_err_msg = case err {
    //   Connection failed
    //
    pog.ConnectionUnavailable -> "Conexão com o Banco de Dados não disponível"

    //   Took too long
    //
    pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"

    // Fallback response
    //
    _ -> "Ocorreu um erro ao acessar o Banco de Dados"
  }

  wisp.internal_server_error()
  |> wisp.set_body(wisp.Text(db_err_msg))
}

fn log_unauthorized_access_attempt(
  user_uuid user_uuid: uuid.Uuid,
  user_role user_role: role.Role,
) -> Nil {
  glight.logger()
  |> glight.with("user", uuid.to_string(user_uuid))
  |> glight.with("role", role.to_string(user_role))
  |> glight.notice("unauthorized_access_attempt")

  Nil
}

fn get_dashboard_stats_row_to_json(
  get_dashboard_stats_row: sql.QueryDashboardStatsRow,
) -> json.Json {
  let sql.QueryDashboardStatsRow(
    active_brigades_count:,
    total_occurrences_count:,
    active_occurrences_count:,
    recent_occurrences_count:,
  ) = get_dashboard_stats_row
  json.object([
    #("totalOcorrencias", json.int(total_occurrences_count)),
    #("ocorrenciasHoje", json.int(recent_occurrences_count)),
    #("emAndamento", json.int(active_occurrences_count)),
    #("equipesAtivas", json.int(active_brigades_count)),
  ])
}

/// Querying the endpoint can fail
pub type GetDashboardStatsError {
  /// DataBase could not find the data
  DataBaseReturnedEmptyRow
  /// DataBase query went wrong
  DataBaseError(pog.QueryError)
  /// User/Role related errors
  RoleError(user.AuthorizationError)
}
