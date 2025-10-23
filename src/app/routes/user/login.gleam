//// Handler for user authentication and login.
////
////   Uses signed cookies to prevent tampering and logs all login attempts.

import app/routes/role
import app/routes/user
import app/routes/user/sql
import app/web.{type Context}
import argus
import formal/form
import gleam/json
import gleam/list
import gleam/result
import glight
import pog
import wisp
import youid/uuid

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
/// On success, sets a cookie on the client containing the User UUID,
/// It will then be used on later requests for authetication.
///
/// The actual Cookie is **encrypted**.
///
/// ## Example
///
/// ```sh
/// set-cookie: USER_ID=0199b58a-acb0-70a8-9de7-0b65a03b8743
/// ```
pub fn handle_request(request request: wisp.Request, ctx ctx: Context) {
  use form_data <- wisp.require_form(request)
  let form_result =
    login_form()
    |> form.add_values(form_data.values)
    |> form.run

  case form_result {
    Error(_) -> wisp.bad_request("Dados inválidos")
    Ok(login_data) ->
      handle_login(
        request:,
        ctx:,
        login_data:,
        cookie_name: user.uuid_cookie_name,
      )
  }
}

fn handle_login(
  request request: wisp.Request,
  ctx ctx: Context,
  login_data login_data: LogIn,
  cookie_name cookie_name: String,
) {
  let login_result = query_login_token(login: login_data, ctx:)
  case login_result {
    Ok(#(json_data, user_uuid)) -> {
      //   Logs user authentication
      log_login(login_data)

      let resp = wisp.json_response(json.to_string(json_data), 200)

      //   Store UUID cookie
      wisp.set_cookie(
        response: resp,
        request: request,
        name: cookie_name,
        value: uuid.to_string(user_uuid),
        security: wisp.Signed,
        //   Cookie lasts 1 hour in total
        max_age: 60 * 60,
      )
    }

    //   Handle possible errors
    Error(err) -> handle_error(err)
  }
}

fn handle_error(err: LoginError) {
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

    //   Database Errors ------------------------------------------------------
    DataBaseError(db_err) -> {
      let internal_err_msg = case db_err {
        pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"
        pog.ConnectionUnavailable ->
          "Conexão com o Banco de Dados não disponível"
        //   Unexpected errors
        _ -> "Ocorreu um erro ao accessar o Banco de Dados"
      }

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(internal_err_msg))
    }
  }
}

///   Logs user registration
fn log_login(login: LogIn) -> Nil {
  glight.logger()
  |> glight.with("registration", login.registration)
  |> glight.info("login")

  Nil
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
fn query_login_token(login data: LogIn, ctx ctx: Context) {
  use returned <- result.try(
    sql.query_login_token(ctx.conn, data.registration)
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

  let user_role =
    row.user_role
    |> enum_to_role

  let json_data =
    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("role", json.string(role.to_string_pt_br(user_role))),
    ])

  case is_correct_password {
    // Return the user's uuid
    True -> Ok(#(json_data, row.id))
    False -> Error(InvalidPassword)
  }
}

fn enum_to_role(user_role: sql.UserRoleEnum) -> role.Role {
  case user_role {
    sql.Admin -> role.Admin
    sql.Analist -> role.Analist
    sql.Captain -> role.Captain
    sql.Developer -> role.Developer
    sql.Firefighter -> role.Firefighter
    sql.Sargeant -> role.Sargeant
  }
}
