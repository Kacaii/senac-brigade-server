import app/sql
import app/web.{type Context}
import argus
import formal/form
import gleam/list
import gleam/result
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
      let login_result = verify_login(login:, ctx:)
      case login_result {
        Ok(_) ->
          wisp.set_body(wisp.ok(), wisp.Text("Login realizado com sucesso"))
        Error(err) -> {
          let error_message = case err {
            //   Input errors
            InvalidPassword -> "Senha incorreta"
            DatabaseReturnedEmptyRow -> "Usuário não cadastrado"
            //   Internal errors
            DataBaseError -> "Ocorreu um erro ao accessar o Banco de Dados"
            HashError -> "Ocorreu um erro ao encriptografar a senha do usuário"
          }

          wisp.internal_server_error()
          |> wisp.set_body(wisp.Text(error_message))
        }
      }
    }
  }
}

type LoginError {
  DatabaseReturnedEmptyRow
  DataBaseError
  InvalidPassword
  HashError
}

fn verify_login(login data: LogIn, ctx ctx: Context) {
  use returned <- result.try(
    sql.get_user_password_by_registration(ctx.conn, data.registration)
    |> result.replace_error(DataBaseError),
  )

  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(DatabaseReturnedEmptyRow),
  )

  use is_correct_password <- result.try(
    argus.verify(data.password, row.password_hash)
    |> result.replace_error(HashError),
  )

  case is_correct_password {
    True -> Ok(Nil)
    False -> Error(InvalidPassword)
  }
}
