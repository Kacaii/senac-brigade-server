import app/domain/brigade/sql
import app/web
import app/web/context.{type Context}
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
  use data <- wisp.require_json(req)

  let decoder = body_decoder()
  case decode.run(data, decoder) {
    Error(err) -> web.handle_decode_error(err)
    Ok(is_active) -> handle_body(ctx, brigade_id, is_active)
  }
}

fn handle_body(
  ctx: Context,
  brigade_id: String,
  is_active: Bool,
) -> wisp.Response {
  case query_database(ctx, brigade_id, is_active) {
    Ok(body) -> wisp.json_response(body, 200)
    Error(err) -> handle_error(err)
  }
}

type UpdateBrigadeStatusError {
  /// Brigade contains invalid Uuid
  InvalidUuid(String)
  /// An error occurred while accessing the DataBase
  DataBase(pog.QueryError)
  /// Brigade not found in the DataBase
  NotFound(String)
}

fn handle_error(err: UpdateBrigadeStatusError) -> wisp.Response {
  case err {
    InvalidUuid(id) -> wisp.bad_request("Equipe possui UUID Inválido: " <> id)
    NotFound(id) -> wisp.bad_request("Equipe não encontrada: " <> id)
    DataBase(err) -> web.handle_database_error(err)
  }
}

fn query_database(
  ctx: Context,
  id: String,
  is_active: Bool,
) -> Result(String, UpdateBrigadeStatusError) {
  use brigade_uuid <- result.try(
    uuid.from_string(id)
    |> result.replace_error(InvalidUuid(id)),
  )

  use returned <- result.try(
    sql.update_brigade_status(ctx.db, brigade_uuid, is_active)
    |> result.map_error(DataBase),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(NotFound(id)),
  )

  [
    #("id", json.string(uuid.to_string(row.id))),
    #("is_active", json.bool(row.is_active)),
    #("updated_at", json.float(timestamp.to_unix_seconds(row.updated_at))),
  ]
  |> json.object
  |> json.to_string
}

fn body_decoder() -> decode.Decoder(Bool) {
  use is_active <- decode.field("ativo", decode.bool)
  decode.success(is_active)
}
