import app/routes/brigade/sql
import app/web
import app/web/context.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result.{try}
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
    Ok(is_active) ->
      case try_update_status(ctx, brigade_id, is_active) {
        Ok(body) -> wisp.json_response(body, 200)
        Error(err) -> handle_error(err)
      }
  }
}

///   Updating a brigade status can fail
type UpdateBrigadeStatusError {
  /// Brigade contains invalid Uuid
  InvalidUuid(String)
  /// An error occurred while accessing the DataBase
  DataBase(pog.QueryError)
  /// Brigade not found in the DataBase
  BrigadeNotFound(String)
}

fn handle_error(err: UpdateBrigadeStatusError) -> wisp.Response {
  case err {
    InvalidUuid(id) -> wisp.bad_request("Equipe possui UUID Inválido: " <> id)
    BrigadeNotFound(id) -> wisp.bad_request("Equipe não encontrada: " <> id)
    DataBase(err) -> web.handle_database_error(err)
  }
}

fn try_update_status(
  ctx: Context,
  id: String,
  is_active: Bool,
) -> Result(String, UpdateBrigadeStatusError) {
  use brigade_uuid <- try(
    uuid.from_string(id) |> result.replace_error(InvalidUuid(id)),
  )

  use returned <- try(
    sql.update_brigade_status(ctx.db, brigade_uuid, is_active)
    |> result.map_error(DataBase),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(BrigadeNotFound(id)),
  )

  json.to_string(
    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("is_active", json.bool(row.is_active)),
      #("updated_at", json.float(timestamp.to_unix_seconds(row.updated_at))),
    ]),
  )
}

fn body_decoder() -> decode.Decoder(Bool) {
  use is_active <- decode.field("ativo", decode.bool)
  decode.success(is_active)
}
