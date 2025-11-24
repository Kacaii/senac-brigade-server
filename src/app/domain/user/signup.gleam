//// Handler for user registration and account creation.
////
//// It creates new user accounts by validating form data and inserting
//// the user information into the database with proper password hashing.
////
//// Passwords are hashed using Argon2 before storage and all sensitive
//// operations are logged for audit purposes.

import app/domain/role
import app/domain/user
import app/domain/user/sql
import app/web
import app/web/context.{type Context}
import argus
import formal/form
import gleam/json
import gleam/list
import gleam/result
import glight
import pog
import wisp
import youid/uuid

///   Insert a new `user_account` into the database
///
/// - Registration must be unique
/// - Email must be unique
///
/// Only accessible to Admin users
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use form_data <- wisp.require_form(req)
  let form_result =
    signup_form()
    |> form.add_values(form_data.values)
    |> form.run

  case form_result {
    Error(_) -> wisp.unprocessable_content()
    Ok(body) -> handle_body(req, body, ctx)
  }
}

fn handle_body(req: wisp.Request, body: SignUp, ctx: Context) -> wisp.Response {
  case try_insert_into_database(request: req, ctx:, signup: body) {
    Ok(new_user) -> {
      log_signup(body)
      wisp.json_response(new_user, 201)
    }

    //   Server errors ----------------------------------------------------
    Error(err) -> handle_error(req, err)
  }
}

/// 󰆼  Inserts the user in the database.
/// 󱔼  Hashes the user `password` before inserting.
fn try_insert_into_database(
  request request: wisp.Request,
  signup data: SignUp,
  ctx ctx: Context,
) -> Result(String, SignupError) {
  use _ <- result.try(
    user.check_role_authorization(
      request:,
      ctx:,
      cookie_name: user.uuid_cookie_name,
      authorized_roles: [role.Admin, role.Developer],
    )
    |> result.map_error(AccessError),
  )

  use hashed_password <- result.try(
    argus.hasher()
    |> argus.hash(data.password, argus.gen_salt())
    |> result.replace_error(HashError),
  )

  use user_role <- result.try(
    role.from_string_pt_br(data.user_role)
    |> result.map_error(InvalidRole),
  )

  use returned <- result.try(
    sql.insert_new_user(
      ctx.db,
      data.name,
      data.registration,
      data.phone_number,
      data.email,
      hashed_password.encoded_hash,
      role_to_enum(user_role),
    )
    |> result.map_error(DataBase),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(MissingSignupConfirmation),
  )

  json.object([#("id", json.string(uuid.to_string(row.id)))])
  |> json.to_string
}

type SignUp {
  SignUp(
    name: String,
    registration: String,
    phone_number: String,
    email: String,
    password: String,
    user_role: String,
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
    use user_role <- form.field("cargo", {
      form.parse_string |> form.check_not_empty()
    })

    form.success(SignUp(
      name:,
      registration:,
      phone_number:,
      email:,
      password:,
      user_role:,
    ))
  })
}

fn log_signup(signup: SignUp) -> Nil {
  glight.logger()
  |> glight.with("name", signup.name)
  |> glight.with("registration", signup.registration)
  |> glight.with("phone_number", signup.phone_number)
  |> glight.with("email", signup.email)
  |> glight.info("signup")

  Nil
}

fn handle_database_error(err: pog.QueryError) -> wisp.Response {
  case err {
    pog.ConstraintViolated(_, _, constraint: "user_account_registration_key") -> {
      let resp = wisp.response(409)
      let body = wisp.Text("Matrícula já cadastrada. Experimente fazer login")

      wisp.set_body(resp, body)
    }

    pog.ConstraintViolated(_, _, constraint: "user_account_email_key") -> {
      let resp = wisp.response(409)
      let body =
        wisp.Text("Email já cadastrado. Por favor, utilize um diferente")

      wisp.set_body(resp, body)
    }

    pog.ConstraintViolated(_, _, constraint: "user_account_phone_key") -> {
      let resp = wisp.response(409)
      let body =
        wisp.Text("Telefone já cadastrado. Por favor, utilize um diferente")

      wisp.set_body(resp, body)
    }

    err -> web.handle_database_error(err)
  }
}

fn handle_error(req: wisp.Request, err: SignupError) {
  case err {
    HashError -> {
      let body =
        "Ocorreu um erro ao encriptografar a senha do usuário"
        |> wisp.Text

      wisp.internal_server_error()
      |> wisp.set_body(body)
    }
    DataBase(err) -> handle_database_error(err)
    InvalidRole(unknown) ->
      wisp.bad_request("O novo usuário possui um cargo inválido: " <> unknown)
    AccessError(err) -> user.handle_access_control_error(req, err)
    MissingSignupConfirmation ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "Não foi possível confirmar a inserção do novo usuário no sistema",
      ))
  }
}

///   Signup can fail
type SignupError {
  /// 󱔼  Hashing went wrong
  HashError
  ///   Something went wrong on the database
  DataBase(pog.QueryError)
  ///   Unknown user role
  InvalidRole(String)
  ///   User / Role related issues
  AccessError(user.AccessControlError)
  /// 󰡦  Database didnt return information about the new user
  MissingSignupConfirmation
}

fn role_to_enum(user_role: role.Role) -> sql.UserRoleEnum {
  case user_role {
    role.Admin -> sql.Admin
    role.Analyst -> sql.Analyst
    role.Captain -> sql.Captain
    role.Developer -> sql.Developer
    role.Firefighter -> sql.Firefighter
    role.Sargeant -> sql.Sargeant
  }
}
