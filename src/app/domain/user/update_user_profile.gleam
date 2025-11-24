import app/domain/user
import app/domain/user/sql
import app/web
import app/web/context.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import pog
import wisp
import youid/uuid

/// 󰚰  Allows an user to update their basic information like name, email and
/// phone number, then return the updated values as JSON.
///
/// ## Response
///
/// ```json
/// {
///   "full_name": "Ninguém da Silva",
///   "email": "email.novo@email.com",
///   "phone": "9811111111"
/// }
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Put)
  use json_body <- wisp.require_json(req)

  case decode.run(json_body, request_body_decoder()) {
    Error(err) -> web.handle_decode_error(err)
    Ok(body) -> handle_body(req, ctx, body)
  }
}

fn handle_body(
  req: wisp.Request,
  ctx: Context,
  body: RequestBody,
) -> wisp.Response {
  case try_update_user(req, ctx, body) {
    Ok(resp) -> wisp.json_response(resp, 200)
    Error(err) -> handle_error(err)
  }
}

fn handle_error(err: UpdateProfileError) -> wisp.Response {
  case err {
    AccessControl(err) -> user.handle_authentication_error(err)
    UserNotFound(user_uuid) -> {
      let resp = wisp.not_found()
      let body =
        wisp.Text(
          "Usuário não encontrado no Banco de Dados: "
          <> uuid.to_string(user_uuid),
        )

      wisp.set_body(resp, body)
    }
    DatabaseError(err) -> {
      case err {
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
  }
}

fn try_update_user(
  req: wisp.Request,
  ctx: Context,
  body: RequestBody,
) -> Result(String, UpdateProfileError) {
  use maybe_id <- result.try(
    user.extract_uuid(req, user.uuid_cookie_name)
    |> result.map_error(AccessControl),
  )

  use returned <- result.try(
    sql.update_user_profile(
      ctx.db,
      maybe_id,
      body.full_name,
      body.email,
      body.phone,
    )
    |> result.map_error(DatabaseError),
  )

  case list.first(returned.rows) {
    Error(_) -> Error(UserNotFound(maybe_id))
    Ok(row) -> {
      json.object([
        #("full_name", json.string(row.full_name)),
        #("email", json.string(row.email)),
        #("phone", json.nullable(row.phone, json.string)),
      ])
      |> json.to_string
      |> Ok
    }
  }
}

/// Updating an user profile can fail
type UpdateProfileError {
  /// Authentication failed
  AccessControl(user.AuthenticationError)
  /// An error occurred when accessing the DataBase
  DatabaseError(pog.QueryError)
  /// User was not found in the DataBase
  UserNotFound(uuid.Uuid)
}

type RequestBody {
  RequestBody(full_name: String, email: String, phone: String)
}

fn request_body_decoder() -> decode.Decoder(RequestBody) {
  use full_name <- decode.field("full_name", decode.string)
  use email <- decode.field("email", decode.string)
  use phone <- decode.field("phone", decode.string)
  decode.success(RequestBody(full_name:, email:, phone:))
}
