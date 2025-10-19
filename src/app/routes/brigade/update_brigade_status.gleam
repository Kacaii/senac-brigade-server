import app/routes/brigade/sql
import app/web.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import gleam/time/timestamp
import pog
import wisp
import youid/uuid

/// 󰚰  Update the status of the brigade `is_active` field
/// and return the updated state as formatted JSON
///
/// ```json
/// {
///   "id": "c3d4e5f6-g7h8-9012-cdef-345678901234",
///   "is_active": true,
///   "updated_at": 1759790156.0
/// }
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id brigade_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Put)
  use json_data <- wisp.require_json(req)

  case decode.run(json_data, is_active_decoder()) {
    Error(_) -> wisp.unprocessable_content()
    Ok(is_active) -> {
      case try_update_status(ctx, brigade_id, is_active) {
        Ok(resp) -> wisp.json_response(json.to_string(resp), 200)
        Error(err) -> handle_error(err)
      }
    }
  }
}

fn handle_error(err: UpdateBrigadeStatusError) -> wisp.Response {
  case err {
    InvalidBrigadeUuid(id) ->
      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text(
        "Brigada de incêndio possui UUID Inválido: " <> id,
      ))
    UuidNotFound(id) -> wisp.bad_request("Equipe não encontrada: " <> id)
    DataBaseError(err) -> handle_database_error(err)
  }
}

fn handle_database_error(err: pog.QueryError) -> wisp.Response {
  let err_msg = case err {
    pog.ConnectionUnavailable -> "Conexão com o Banco de Dados não disponível"
    pog.ConstraintViolated(message:, constraint:, detail:) ->
      constraint <> ": " <> message <> "\n" <> detail
    pog.PostgresqlError(code:, name:, message:) ->
      code <> ": " <> name <> "\n" <> message
    pog.QueryTimeout -> "O Banco de Dados demorou muito pra responder"
    _ -> "Ocorreu um erro no Banco de dados"
  }

  wisp.internal_server_error()
  |> wisp.set_body(wisp.Text(err_msg))
}

fn try_update_status(
  ctx: Context,
  id: String,
  is_active: Bool,
) -> Result(json.Json, UpdateBrigadeStatusError) {
  use brigade_uuid <- result.try(
    uuid.from_string(id) |> result.replace_error(InvalidBrigadeUuid(id)),
  )
  use returned <- result.try(
    sql.update_brigade_status(ctx.conn, brigade_uuid, is_active)
    |> result.map_error(DataBaseError),
  )
  use row <- result.try(
    list.first(returned.rows)
    |> result.replace_error(UuidNotFound(id)),
  )

  Ok(
    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("is_active", json.bool(row.is_active)),
      #("updated_at", json.float(timestamp.to_unix_seconds(row.updated_at))),
    ]),
  )
}

fn is_active_decoder() -> decode.Decoder(Bool) {
  use is_active <- decode.field("ativo", decode.bool)
  decode.success(is_active)
}

type UpdateBrigadeStatusError {
  InvalidBrigadeUuid(String)
  DataBaseError(pog.QueryError)
  UuidNotFound(String)
}
