
import app/routes/user
import app/routes/user/sql
import app/web.{type Context}
import argus
import formal/form
import gleam/http
import gleam/list
import gleam/result
import glight
import pog
import wisp
import youid/uuid

/// 󰚰  Update an user password
///
/// - Current password must match the one inside the DataBase
/// - New password must be different than the current one
///
///   Extracts the user UUID form the request's Cookies
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Put)
  use form_data <- wisp.require_form(request)
  let form_result =
    update_password_form()
    |> form.add_values(form_data.values)
    |> form.run()

  case form_result {
    Error(_) -> wisp.bad_request("Formulário inválido")
    Ok(form_data) -> handle_form_data(request:, ctx:, form_data:)
  }
}

fn handle_form_data(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data form_data: UpdatePasswordForm,
) -> wisp.Response {
  case update_user_password(request:, ctx:, form_data:) {
    Error(err) -> handle_error(err)
    Ok(_) ->
      wisp.ok() |> wisp.set_body(wisp.Text("Senha atualizada com sucesso!"))
  }
}

fn handle_error(err: UpdatePasswordError) -> wisp.Response {
  case err {
    AuthenticationError(err) -> user.handle_authentication_error(err)
    FailedToQueryCurrentPassword ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "Não foi possível consultar a senha do usuário",
      ))
    HashError ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "Ocorreu um erro ao encriptografar a senha do usuário",
      ))
    WrongPassword -> wisp.bad_request("Senha incorreta")
    DataBaseError(err) -> web.handle_database_error(err)
    MustBeDifferent ->
      wisp.bad_request("A senha nova precisa ser diferente da antiga")
  }
}

fn update_user_password(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data form_data: UpdatePasswordForm,
) -> Result(pog.Returned(Nil), UpdatePasswordError) {
  use user_uuid <- result.try(
    user.auth_user_from_cookie(request:, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AuthenticationError),
  )

  // Fetch the password hash from the DataBase
  use current_password_hash <- result.try(query_user_password(ctx:, user_uuid:))

  // Compare the current password with the hash
  use match_current_password <- result.try(
    argus.verify(current_password_hash, form_data.current_password)
    |> result.replace_error(HashError),
  )

  // Compare the new password with the hash
  use match_new_password <- result.try(
    argus.verify(current_password_hash, form_data.new_password)
    |> result.replace_error(HashError),
  )

  case match_current_password, match_new_password {
    // User typed correct password and the new one is different from the stored hash
    True, False -> {
      // 󱔼  Hash the password first before updating
      use hashed_password <- result.try(
        argus.hasher()
        |> argus.hash(form_data.new_password, argus.gen_salt())
        |> result.replace_error(HashError),
      )

      // 󰚰  Update their password
      use returned <- result.try(
        sql.update_user_password(
          ctx.conn,
          user_uuid,
          hashed_password.encoded_hash,
        )
        |> result.map_error(DataBaseError),
      )

      //   All done!
      log_password_update(user_uuid)
      Ok(returned)
    }

    // User typed wrong password
    False, _ -> Error(WrongPassword)

    // New password is the same as the stored hash
    _, True -> Error(MustBeDifferent)
  }
}

fn query_user_password(
  ctx ctx: Context,
  user_uuid user_uuid: uuid.Uuid,
) -> Result(String, UpdatePasswordError) {
  use returned <- result.try(
    sql.query_user_password(ctx.conn, user_uuid)
    |> result.map_error(DataBaseError),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(FailedToQueryCurrentPassword),
  )

  // 󱔼  Return the hashed password
  row.password_hash
}

fn update_password_form() -> form.Form(UpdatePasswordForm) {
  form.new({
    use current_password <- form.field("senhaAtual", {
      form.parse_string |> form.check_not_empty()
    })
    use new_password <- form.field("novaSenha", {
      form.parse_string
      |> form.check_not_empty()
      |> form.check(fn(value) {
        case value == current_password {
          False -> Ok(value)
          True -> Error("Nova senha deve ser diferente da atual")
        }
      })
    })

    use _ <- form.field("confirmarSenha", {
      form.parse_string |> form.check_confirms(new_password)
    })

    // Success!
    form.success(UpdatePasswordForm(current_password:, new_password:))
  })
}

type UpdatePasswordForm {
  UpdatePasswordForm(current_password: String, new_password: String)
}

type UpdatePasswordError {
  AuthenticationError(user.AuthenticationError)
  FailedToQueryCurrentPassword
  DataBaseError(pog.QueryError)
  WrongPassword
  HashError
  MustBeDifferent
}

fn log_password_update(user_uuid: uuid.Uuid) -> Nil {
  glight.logger()
  |> glight.with("user_uuid", uuid.to_string(user_uuid))
  |> glight.info("password_update")

  Nil
}
