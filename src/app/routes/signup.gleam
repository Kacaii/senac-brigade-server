import app/sql
import app/web.{type Context}
import argus
import formal/form
import gleam/result
import gleam/string
import pog
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
pub fn handle_form_submission(
  request req: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use form_data <- wisp.require_form(req)
  let form_result =
    signup_form()
    |> form.add_values(form_data.values)
    |> form.run

  case form_result {
    //   User errors ----------------------------------------------------------
    Error(_) -> wisp.unprocessable_content()

    //   Valid form
    Ok(signup) -> {
      case try_insert_into_database(signup:, ctx:) {
        Ok(_) -> {
          wisp.created()
          |> wisp.set_body(wisp.Text("Cadastro realizado com sucesso"))
        }
        //   Server errors ----------------------------------------------------
        Error(err) -> {
          let error_message = case err {
            // 󱔼  Hashing went wrong
            HashError -> {
              "Ocorreu um erro ao encriptografar a senha do usuário"
            }
            //   Something when wrong inside the database
            DataBaseError(err) -> {
              case err {
                pog.ConnectionUnavailable ->
                  "Conexão com o banco de dados não disponível"
                pog.QueryTimeout ->
                  "O banco de dados demorou muito para responder, talvez tenha perdido a conexão?"
                pog.ConstraintViolated(message:, constraint:, detail:) -> {
                  case constraint {
                    //   Registration must be unique --------------------------
                    "user_account_registration_key" ->
                      "
                      Matrícula {{registration}} já cadastrada
                      Experimente fazer login
                      "
                      |> string.replace("{{registration}}", signup.registration)
                    // 󰇮  Email must be unique ---------------------------------
                    "user_account_email_key" ->
                      "
                      Email: {{email}} já cadastrado
                      Por favor, utilize um diferente
                      "
                      |> string.replace("{{email}}", signup.email)
                    //   Some other constrain ---------------------------------
                    _ ->
                      "
                      🐘  O banco de dados apresentou um erro

                      Constraint: {{constraint}}
                      Mensagem:   {{message}}
                      Detalhe:    {{detail}}
                      "
                      |> string.replace("{{constraint}}", constraint)
                      |> string.replace("{{message}}", message)
                      |> string.replace("{{detail}}", detail)
                  }
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
                _ -> "Ocorreu um erro ao inserir o usuário no banco de dados"
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

///   Signup can fail
type SignupError {
  /// 󱔼  Hashing went wrong
  HashError
  ///   Something went wrong on the database
  DataBaseError(pog.QueryError)
}

/// 󰆼  Inserts the user in the database.
/// 󱔼  Hashes the user `password` before inserting.
fn try_insert_into_database(
  signup data: SignUp,
  ctx ctx: Context,
) -> Result(Nil, SignupError) {
  use hashed_password <- result.try(
    argus.hasher()
    |> argus.hash(data.password, argus.gen_salt())
    |> result.replace_error(HashError),
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
    |> result.map_error(DataBaseError),
  )

  // No need to return anything from this function
  Ok(Nil)
}
