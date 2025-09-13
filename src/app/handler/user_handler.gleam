import app/sql
import app/web.{type Context}
import gleam/list
import gleam/result
import wisp

type RegisterUserFormData {
  RegisterUserFormData(
    name: String,
    registration: String,
    email: String,
    password: String,
    confirm_password: String,
  )
}

///   Register a new user on our database
pub fn register_new_user(req: wisp.Request, ctx: Context) -> wisp.Response {
  use form_data <- wisp.require_form(req)
  let form_result = {
    use name <- result.try(list.key_find(form_data.values, "nome"))
    use registration <- result.try(list.key_find(form_data.values, "matricula"))
    use email <- result.try(list.key_find(form_data.values, "email"))
    use password <- result.try(list.key_find(form_data.values, "senha"))
    use confirm_password <- result.try(list.key_find(
      form_data.values,
      "confirma_senha",
    ))

    Ok(RegisterUserFormData(
      name:,
      registration:,
      email:,
      password:,
      confirm_password:,
    ))
  }

  case form_result {
    Error(_) -> wisp.bad_request("Dados inválidos")
    Ok(user_form_data) -> {
      let register_result =
        sql.register_new_user(
          ctx.conn,
          user_form_data.name,
          user_form_data.registration,
          user_form_data.email,
          user_form_data.password,
        )

      case register_result {
        Error(_) -> wisp.internal_server_error()
        Ok(_) -> wisp.created()
      }
    }
  }
}
