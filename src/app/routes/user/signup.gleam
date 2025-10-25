//// Handler for user registration and account creation.
////
//// It creates new user accounts by validating form data and inserting
//// the user information into the database with proper password hashing.
////
//// Passwords are hashed using Argon2 before storage and all sensitive
//// operations are logged for audit purposes.

import app/database
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
    //   User errors ----------------------------------------------------------
    Error(_) -> wisp.unprocessable_content()

    //   Valid form
    Ok(signup) -> {
      case try_insert_into_database(request: req, ctx:, signup:) {
        Ok(new_user) -> {
          log_signup(signup)
          wisp.json_response(json.to_string(new_user), 201)
        }

        //   Server errors ----------------------------------------------------
        Error(err) -> handle_error(req, err)
      }
    }
  }
}

/// 󰆼  Inserts the user in the database.
/// 󱔼  Hashes the user `password` before inserting.
fn try_insert_into_database(
  request request: wisp.Request,
  signup data: SignUp,
  ctx ctx: Context,
) -> Result(json.Json, SignupError) {
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
      ctx.conn,
      data.name,
      data.registration,
      data.phone_number,
      data.email,
      hashed_password.encoded_hash,
      role_to_enum(user_role),
    )
    |> result.map_error(DataBaseError),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(MissingSignupConfirmation),
  )

  json.object([#("id", json.string(uuid.to_string(row.id)))])
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
      "Matrícula já cadastrada. Experimente fazer login"
      |> wisp.bad_request()
    }
    pog.ConstraintViolated(_, _, constraint: "user_account_email_key") -> {
      "Email já cadastrado. Por favor, utilize um diferente"
      |> wisp.bad_request()
    }

    err -> database.handle_database_error(err)
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
    DataBaseError(err) -> handle_database_error(err)
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
  DataBaseError(pog.QueryError)
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
