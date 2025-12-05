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
  use body <- wisp.require_json(req)

  case decode.run(body, body_decoder()) {
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
    Error(err) -> handle_error(err)
    Ok(resp) -> wisp.json_response(resp, 200)
  }
}

fn handle_error(err: UpdateProfileError) -> wisp.Response {
  case err {
    Authentication(err) -> user.handle_authentication_error(err)

    NotFound(id) -> {
      let body = "Usuário não encontrado" <> uuid.to_string(id)
      wisp.Text(body)
      |> wisp.set_body(wisp.not_found(), _)
    }

    Database(err) -> {
      case err {
        pog.ConstraintViolated(_, _, constraint: "user_account_email_key") -> {
          "Email já cadastrado. Por favor, utilize um diferente"
          |> wisp.Text
          |> wisp.set_body(wisp.response(409), _)
        }

        pog.ConstraintViolated(_, _, constraint: "user_account_phone_key") -> {
          "Telefone já cadastrado. Por favor, utilize um diferente"
          |> wisp.Text
          |> wisp.set_body(wisp.response(409), _)
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
    |> result.map_error(Authentication),
  )

  use returned <- result.try(
    sql.update_user_profile(
      ctx.db,
      maybe_id,
      body.full_name,
      body.email,
      body.phone,
    )
    |> result.map_error(Database),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(NotFound(maybe_id)),
  )

  [
    #("full_name", json.string(row.full_name)),
    #("email", json.string(row.email)),
    #("phone", json.nullable(row.phone, json.string)),
  ]
  |> json.object
  |> json.to_string
}

type UpdateProfileError {
  /// Authentication failed
  Authentication(user.AuthenticationError)
  /// An error occurred when accessing the DataBase
  Database(pog.QueryError)
  /// User was not found in the DataBase
  NotFound(uuid.Uuid)
}

type RequestBody {
  RequestBody(full_name: String, email: String, phone: String)
}

fn body_decoder() -> decode.Decoder(RequestBody) {
  use full_name <- decode.field("full_name", decode.string)
  use email <- decode.field("email", decode.string)
  use phone <- decode.field("phone", decode.string)
  decode.success(RequestBody(full_name:, email:, phone:))
}
