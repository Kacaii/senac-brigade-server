import app/sql
import app/web.{type Context}
import argus
import formal/form
import gleam/list
import gleam/result
import gleam/string
import pog
import wisp

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

///   Verifies if a user is registred
pub fn handle_form_submission(req req: wisp.Request, ctx ctx: Context) {
  use form_data <- wisp.require_form(req)
  let form_result =
    login_form()
    |> form.add_values(form_data.values)
    |> form.run

  case form_result {
    Error(_) -> wisp.bad_request("Dados inválidos")
    Ok(login) -> {
      let login_result = try_login(login:, ctx:)
      case login_result {
        Ok(_) ->
          wisp.set_body(wisp.ok(), wisp.Text("Login realizado com sucesso"))
        Error(err) -> {
          let error_message = case err {
            //   User errors --------------------------------------------------
            InvalidPassword -> "Senha incorreta"
            DataBaseReturnedEmptyRow -> "Usuário não cadastrado"
            //   Server errors ------------------------------------------------
            HashError -> "Ocorreu um erro ao encriptografar a senha do usuário"
            //   Database Errors
            DataBaseError(db_err) -> {
              case db_err {
                pog.QueryTimeout ->
                  "O banco de dados demorou muito para responder, talvez tenha perdido a conexão?"
                pog.ConnectionUnavailable ->
                  "Conexão com o banco de dados não disponível"
                pog.ConstraintViolated(message:, constraint:, detail:) -> {
                  "
                    Uma das restrições do banco de dados foi violada

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
                    O banco de dados apresentou um erro

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
            }
          }

          wisp.internal_server_error()
          |> wisp.set_body(wisp.Text(error_message))
        }
      }
    }
  }
}

type LoginError {
  DataBaseReturnedEmptyRow
  DataBaseError(pog.QueryError)
  InvalidPassword
  HashError
}

fn try_login(login data: LogIn, ctx ctx: Context) {
  use returned <- result.try(
    sql.get_user_password_by_registration(ctx.conn, data.registration)
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
    True -> Ok(Nil)
    False -> Error(InvalidPassword)
  }
}
