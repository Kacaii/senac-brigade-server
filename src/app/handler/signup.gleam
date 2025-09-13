import app/sql
import app/web.{type Context}
import formal/form
import wisp

type SignUp {
  SignUp(name: String, registration: String, email: String, password: String)
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
    use email <- form.field("email", {
      form.parse_email |> form.check_not_empty()
    })
    use password <- form.field("senha", {
      form.parse_string |> form.check_not_empty()
    })
    use _ <- form.field("confirma_senha", {
      form.parse_string |> form.check_confirms(password)
    })

    form.success(SignUp(name:, registration:, email:, password:))
  })
}

///   Inserts a new user account on the database
pub fn handle_form_submission(req: wisp.Request, ctx: Context) -> wisp.Response {
  use form_data <- wisp.require_form(req)
  let form_result =
    signup_form()
    |> form.add_values(form_data.values)
    |> form.run

  case form_result {
    Error(_) -> wisp.bad_request("Dados inválidos")
    Ok(signup_data) -> {
      let register_result =
        // TODO: 󱔼  Hash the password before storing it
        sql.register_new_user(
          ctx.conn,
          signup_data.name,
          signup_data.registration,
          signup_data.email,
          signup_data.password,
        )

      case register_result {
        Error(_) -> wisp.internal_server_error()
        Ok(_) -> wisp.created()
      }
    }
  }
}
