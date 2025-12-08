//// Handler for user authentication and login.
////
////   Uses signed cookies to prevent tampering and logs all login attempts.

import app/domain/role
import app/domain/user
import app/domain/user/sql
import app/web
import app/web/context.{type Context}
import argus
import formal/form
import gleam/bool
import gleam/float
import gleam/http/response
import gleam/json
import gleam/list
import gleam/result
import gleam/time/duration
import glight
import pog
import wisp
import youid/uuid

type RequestBody {
  RequestBody(registration: String, password: String)
}

type LoginError {
  ///   Database couldn't find target registration
  UserNotFound
  ///   Something went wrong on the database
  DataBase(pog.QueryError)
  /// 󰣮  Provided password didnt _match_ the one inside our Database
  InvalidPassword
  /// 󱔼  Hashing went wrong
  HashError
}

type LoginToken {
  LoginToken(body: String, user_id: uuid.Uuid)
}

/// 󱐁  A form that decodes the `LogIn` value.
fn login_form() -> form.Form(RequestBody) {
  form.new({
    use registration <- form.field("matricula", {
      form.parse_string |> form.check_not_empty()
    })

    use password <- form.field("senha", {
      form.parse_string |> form.check_not_empty()
    })

    form.success(RequestBody(registration:, password:))
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
    Error(_) -> wisp.unprocessable_content()
    Ok(data) ->
      user.uuid_cookie_name
      |> handle_login(request:, ctx:, data:, cookie_name: _)
  }
}

fn handle_login(
  request request: wisp.Request,
  ctx ctx: Context,
  data data: RequestBody,
  cookie_name cookie_name: String,
) -> response.Response(wisp.Body) {
  case query_database(data:, ctx:) {
    Error(err) -> handle_error(err)
    Ok(resp) -> {
      log_login(data)
      set_token(resp, request, cookie_name)
    }
  }
}

fn set_token(
  resp: LoginToken,
  request: wisp.Request,
  cookie_name name: String,
) -> wisp.Response {
  let response = wisp.json_response(resp.body, 200)
  let value = uuid.to_string(resp.user_id)
  let security = wisp.Signed

  let max_age =
    duration.hours(1)
    |> duration.to_seconds
    |> float.round

  wisp.set_cookie(response:, request:, name:, value:, security:, max_age:)
}

fn handle_error(err: LoginError) -> response.Response(wisp.Body) {
  case err {
    InvalidPassword ->
      "Senha incorreta"
      |> wisp.Text
      |> wisp.set_body(wisp.response(401), _)

    UserNotFound ->
      "Usuário não cadastrado"
      |> wisp.Text()
      |> wisp.set_body(wisp.response(404), _)

    HashError ->
      "Ocorreu um erro ao encriptografar a senha do usuário"
      |> wisp.Text
      |> wisp.set_body(wisp.response(401), _)

    DataBase(err) -> web.handle_database_error(err)
  }
}

///   Logs user registration
fn log_login(login: RequestBody) -> Nil {
  glight.logger()
  |> glight.with("registration", login.registration)
  |> glight.info("login")

  Nil
}

///   Check if the provided password matches the one inside our database
/// Returns the user's UUID if successfull.
fn query_database(
  data data: RequestBody,
  ctx ctx: Context,
) -> Result(LoginToken, LoginError) {
  use returned <- result.try(
    sql.query_login_token(ctx.db, data.registration)
    |> result.map_error(DataBase),
  )

  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(UserNotFound),
  )

  use correct_password <- result.try(
    argus.verify(row.password_hash, data.password)
    |> result.replace_error(HashError),
  )

  use <- bool.guard(correct_password == False, Error(InvalidPassword))

  let user_role = case row.user_role {
    sql.Admin -> role.Admin
    sql.Analyst -> role.Analyst
    sql.Captain -> role.Captain
    sql.Developer -> role.Developer
    sql.Firefighter -> role.Firefighter
    sql.Sargeant -> role.Sargeant
  }

  json.object([
    #("id", json.string(uuid.to_string(row.id))),
    #("role", json.string(role.to_string_pt_br(user_role))),
  ])
  |> json.to_string
  |> LoginToken(body: _, user_id: row.id)
  |> Ok
}
