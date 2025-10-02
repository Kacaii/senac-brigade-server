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
      authorized_roles: [role.Admin, role.Analist],
    )
    |> result.map_error(RoleError),
  )

  //  QUERY THE DATABASE ----------------------------------------------------
  use returned <- result.try(
    sql.get_dashboard_stats(ctx.conn)
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
    DataBaseError(err) -> {
      let err_message = case err {
        //
        //   Connection failed
        pog.ConnectionUnavailable ->
          "Conexão com o Banco de Dados não disponível"

        //   Took too long
        pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"

        // Fallback
        _ -> "Ocorreu um erro ao acessar o Banco de Dados"
      }

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(err_message))
    }

    //   PERMISSION DENIED ------------------------------------------------
    RoleError(role_err) -> {
      case role_err {
        //   User didn't have a valid UUID
        //
        user.InvalidUUID(user_id) ->
          wisp.bad_request("O usuário não possui UUID válido: " <> user_id)

        //   USER_ID cookie is required to access this endpoint
        //
        user.MissingCookie ->
          wisp.bad_request("Cookie de indentificação ausente")

        // 󱏊  Database couldn't find a user role with that UUDI
        //
        user.DataBaseReturnedEmptyRow ->
          wisp.bad_request("Não foi encontrado um cargo com o ID solicitado")

        //   User is not authorized to access this endpoint -------------------
        //
        user.Unauthorized(user_uuid, user_role) -> {
          //   Log who tried to access and whats their role
          log_unauthorized_access_attempt(user_uuid:, user_role:)
          //   403 FORBIDDEN response
          wisp.response(403)
          |> wisp.set_body(wisp.Text(
            "Usuário não autorizado: " <> role.to_string(user_role),
          ))
        }

        //   DATABASE ERRORS ----------------------------------------------
        //
        user.DataBaseError(db_err) -> {
          let db_err_msg = case db_err {
            //   Connection failed
            //
            pog.ConnectionUnavailable ->
              "Conexão com o Banco de Dados não disponível"

            //   Took too long
            //
            pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"

            // Fallback response
            //
            _ -> "Ocorreu um erro ao verificar o cargo do usuário"
          }

          wisp.internal_server_error()
          |> wisp.set_body(wisp.Text(db_err_msg))
        }
      }
    }
  }
}

fn log_unauthorized_access_attempt(
  user_uuid user_uuid: uuid.Uuid,
  user_role user_role: role.Role,
) -> Nil {
  glight.logger()
  |> glight.with("user", uuid.to_string(user_uuid))
  |> glight.with("role", role.to_string(user_role))
  |> glight.notice("unauthorized_access_attempt")

  glight.set_log_level(glight.Debug)
}

fn get_dashboard_stats_row_to_json(
  get_dashboard_stats_row: sql.GetDashboardStatsRow,
) -> json.Json {
  let sql.GetDashboardStatsRow(
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
  RoleError(user.UserAccountError)
}
