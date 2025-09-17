import app/sql
import app/web.{type Context}
import argus
import formal/form
import gleam/result
import wisp

type SignUp {
  SignUp(
    name: String,
    registration: String,
    phone_number: String,
    email: String,
    password: String,
  )
}

/// 󱐁  A form that decodes the `SignUp` value.
fn signup_form() -> form.Form(SignUp) {
  form.new({
    use name <- form.field("nome", {
      form.parse_string |> form.check_not_empty()
    })
    use registration <- form.field("matricula", {
      form.parse_string |> form.check_not_empty()
    })
    use phone_number <- form.field("telefone", {
      form.parse_phone_number |> form.check_not_empty()
    })
    use email <- form.field("email", {
      form.parse_email |> form.check_not_empty()
    })
    use password <- form.field("senha", {
      form.parse_string |> form.check_not_empty()
    })
    use _ <- form.field("confirma_senha", {
      form.parse_string |> form.check_confirms(password)
    })
    form.success(SignUp(name:, registration:, phone_number:, email:, password:))
  })
}

///   Inserts a new `user_account` into the database
pub fn handle_form_submission(req: wisp.Request, ctx: Context) -> wisp.Response {
  use form_data <- wisp.require_form(req)
  let form_result =
    signup_form()
    |> form.add_values(form_data.values)
    |> form.run

  case form_result {
    Error(_) -> wisp.bad_request("Dados inválidos")
    Ok(signup) -> {
      // TODO: Check if the user exists first, before trying to insert.
      // == -------------------------------------------------------- ==
      case insert_in_database(signup:, context: ctx) {
        Error(err) -> {
          let error_message = case err {
            // 󱔼  Hashing went wrong
            HashFailure ->
              wisp.Text("Ocorreu um erro ao encriptografar a senha do usuário")
            //   Something when wrong inside the database
            InsertError ->
              wisp.Text(
                "Ocorreu um erro ao inserir o usuário no banco de dados",
              )
          }

          wisp.internal_server_error()
          |> wisp.set_body({ error_message })
        }

        Ok(_) -> {
          wisp.created()
          // User registred successfully
          |> wisp.set_body(wisp.Text("Cadastro realizado com sucesso"))
        }
      }
    }
  }
}

type SignupError {
  HashFailure
  InsertError
}

fn insert_in_database(
  signup data: SignUp,
  context ctx: Context,
) -> Result(Nil, SignupError) {
  use hashed_password <- result.try(
    argus.hasher()
    |> argus.hash(data.password, argus.gen_salt())
    |> result.replace_error(HashFailure),
  )

  use _ <- result.try(
    sql.register_new_user(
      ctx.conn,
      data.name,
      data.registration,
      data.phone_number,
      data.email,
      hashed_password.encoded_hash,
    )
    |> result.replace_error(InsertError),
  )

  // No need to return anything from this function
  Ok(Nil)
}
