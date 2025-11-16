import app/domain/user
import app/domain/user/sql
import app/web
import app/web/context.{type Context}
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
    Ok(form_data) -> handle_form_data(request:, ctx:, form_data:)
    Error(_) -> {
      let resp = wisp.unprocessable_content()

      "Formulário inválido"
      |> wisp.Text
      |> wisp.set_body(resp, _)
    }
  }
}

fn handle_form_data(
  request request: wisp.Request,
  ctx ctx: Context,
  form_data form_data: UpdatePasswordForm,
) -> wisp.Response {
  case update_user_password(request:, ctx:, form_data:) {
    Error(err) -> handle_error(err)
    Ok(_) -> {
      let resp = wisp.ok()

      "Senha atualizada com sucesso!"
      |> wisp.Text
      |> wisp.set_body(resp, _)
    }
  }
}

fn handle_error(err: UpdatePasswordError) -> wisp.Response {
  case err {
    AccessError(err) -> user.handle_authentication_error(err)
    UserNotFound(id) -> {
      let resp = wisp.not_found()
      let body = "Usuário não encontrado: " <> uuid.to_string(id)

      wisp.Text(body)
      |> wisp.set_body(resp, _)
    }
    HashError -> {
      let resp = wisp.internal_server_error()

      "Ocorreu um erro ao encriptografar a senha do usuário"
      |> wisp.Text
      |> wisp.set_body(resp, _)
    }
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
) -> Result(Nil, UpdatePasswordError) {
  use user_uuid <- result.try(
    user.extract_uuid(request:, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AccessError),
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
    // 1.  User typed correct password 
    // 2.  The new password is different from the stored hash 
    True, False -> {
      // 󱔼  Hash the password first before updating
      use hashed_password <- result.try(
        argus.hasher()
        |> argus.hash(form_data.new_password, argus.gen_salt())
        |> result.replace_error(HashError),
      )

      // 󰚰  Update their password
      use _ <- result.try(
        sql.update_user_password(
          ctx.db,
          user_uuid,
          hashed_password.encoded_hash,
        )
        |> result.map_error(DataBaseError),
      )

      //   All done!
      log_password_update(user_uuid)
      Ok(Nil)
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
    sql.query_user_password(ctx.db, user_uuid)
    |> result.map_error(DataBaseError),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(UserNotFound(user_uuid)),
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

///   Updating an user's password can fail
type UpdatePasswordError {
  ///   Authentication failed
  AccessError(user.AuthenticationError)
  ///   User was not found in the database
  UserNotFound(uuid.Uuid)
  /// 󱙀  Failed to access the DataBase
  DataBaseError(pog.QueryError)
  ///   User typed the wrong password
  WrongPassword
  ///   Failed to hash the user's password
  HashError
  ///   New password must be different from the old one
  MustBeDifferent
}

fn log_password_update(user_uuid: uuid.Uuid) -> Nil {
  glight.logger()
  |> glight.with("user_uuid", uuid.to_string(user_uuid))
  |> glight.info("password_update")

  Nil
}
