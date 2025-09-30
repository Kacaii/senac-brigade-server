//// Handler for user authentication and login.
////
////   Uses signed cookies to prevent tampering and logs all login attempts.

import app/routes/user/sql
import app/web.{type Context}
import argus
import formal/form
import gleam/list
import gleam/result
import gleam/string
import glight
import pog
import wisp
import youid/uuid

const cookie_name = "USER_ID"

type LogIn {
  LogIn(registration: String, password: String)
}

/// 󱐁  A form that decodes the `LogIn` value.
fn login_form() -> form.Form(LogIn) {
  form.new({
    use registration <- form.field("matricula", {
      form.parse_string |> form.check_not_empty()
    })
    use password <- form.field("senha", {
      form.parse_string |> form.check_not_empty()
    })
    form.success(LogIn(registration:, password:))
  })
}

///   Handles user login authentication and session management
pub fn handle_form(request cookie_user_uuid: wisp.Request, ctx ctx: Context) {
  use form_data <- wisp.require_form(cookie_user_uuid)
  let form_result =
    login_form()
    |> form.add_values(form_data.values)
    |> form.run

  case form_result {
    Error(_) -> wisp.bad_request("Dados inválidos")
    Ok(login_data) -> {
      let login_result = get_login_token(login: login_data, ctx:)
      case login_result {
        Ok(user_uuid) -> {
          //   Logs user registration
          log_login(login_data)

          //   Store UUID cookie
          wisp.set_cookie(
            response: wisp.ok(),
            request: cookie_user_uuid,
            name: cookie_name,
            value: uuid.to_string(user_uuid),
            security: wisp.Signed,
            max_age: 60 * 60,
          )
        }

        Error(err) -> {
          case err {
            //   User errors --------------------------------------------------
            InvalidPassword ->
              //   401 Not Authorized
              wisp.response(401) |> wisp.set_body(wisp.Text("Senha incorreta"))
            DataBaseReturnedEmptyRow ->
              wisp.response(401)
              |> wisp.set_body(wisp.Text("Usuário não cadastrado"))

            //   Server errors ------------------------------------------------
            HashError ->
              wisp.internal_server_error()
              |> wisp.set_body(wisp.Text(
                "Ocorreu um erro ao encriptografar a senha do usuário",
              ))

            //   Database Errors
            DataBaseError(db_err) -> {
              let internal_err_msg = case db_err {
                pog.QueryTimeout ->
                  "O banco de dados demorou muito para responder, talvez tenha perdido a conexão?"
                pog.ConnectionUnavailable ->
                  "Conexão com o banco de dados não disponível"
                pog.ConstraintViolated(message:, constraint:, detail:) -> {
                  "
                  🐘  Uma das restrições do banco de dados foi violada

                  Mensagem:     {{message}}
                  Restrição:    {{constraint}}
                  Detalhes:     {{detail}}
                  "
                  |> string.replace("{{message}}", message)
                  |> string.replace("{{constraint}}", constraint)
                  |> string.replace("{{detail}}", detail)
                }
                pog.PostgresqlError(code:, name:, message:) -> {
                  "
                  🐘  O banco de dados apresentou um erro

                  Código:     {{code}}
                  Nome:       {{name}}
                  Mensagem:   {{message}}
                  "
                  |> string.replace("{{code}}", code)
                  |> string.replace("{{name}}", name)
                  |> string.replace("{{message}}", message)
                }

                //   Unexpected errors
                _ -> "Ocorreu um erro ao accessar o Banco de Dados"
              }

              wisp.internal_server_error()
              |> wisp.set_body(wisp.Text(internal_err_msg))
            }
          }
        }
      }
    }
  }
}

fn log_login(login: LogIn) -> Nil {
  glight.logger()
  |> glight.with("registration", login.registration)
  |> glight.info("login")

  glight.set_log_level(glight.Debug)
}

/// Login can fail 
type LoginError {
  ///   Database couldn't find target registration
  DataBaseReturnedEmptyRow
  ///   Something went wrong on the database
  DataBaseError(pog.QueryError)
  /// 󰣮  Provided password didnt _match_ the one inside our Database
  InvalidPassword
  /// 󱔼  Hashing went wrong
  HashError
}

///   Check if the provided password matches the one inside our database
/// Returns the user's UUID if successfull.
fn get_login_token(
  login data: LogIn,
  ctx ctx: Context,
) -> Result(uuid.Uuid, LoginError) {
  use returned <- result.try(
    sql.get_login_token(ctx.conn, data.registration)
    |> result.map_error(DataBaseError),
  )

  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(DataBaseReturnedEmptyRow),
  )

  use is_correct_password <- result.try(
    argus.verify(row.password_hash, data.password)
    |> result.replace_error(HashError),
  )

  case is_correct_password {
    // Return the user's uuid
    True -> Ok(row.id)
    False -> Error(InvalidPassword)
  }
}
