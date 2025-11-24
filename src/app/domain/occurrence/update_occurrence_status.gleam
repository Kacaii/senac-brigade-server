import app/domain/occurrence
import app/domain/occurrence/sql
import app/domain/user
import app/web
import app/web/context.{type Context}
import app/web/socket/message as msg
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import gleam/time/timestamp
import group_registry
import pog
import wisp
import youid/uuid

/// Resolving a occurence can fail
type ResolveOccurrenceError {
  /// Occurrence has invalid Uuid format
  InvalidUuid(String)
  /// Occurrence was not found in the DataBase
  OccurrenceNotFound(uuid.Uuid)
  /// An error occurred whe naccessing the DataBase
  DataBase(pog.QueryError)
  /// Errors related to authentication / authorization
  AccessControl(user.AuthenticationError)
}

/// 󰚰  Updates the `resolved_at` field of a occurrence
///
/// ```jsonc
/// {
///   "id": "a32fb57f-b547-434d-a5d6-2a2c96cddb20",
///   "resolved_at": 1762889998.0, // or null
///   "updated_at": 1762889998.0
/// }
/// ````
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id occurrence_id: String,
) -> wisp.Response {
  case req.method {
    // Mark an occurrence as resolved
    http.Post ->
      case try_resolve_occurrence(req, ctx, occurrence_id) {
        Error(err) -> handle_error(err)
        Ok(body) -> wisp.json_response(body, 200)
      }

    // Reopen a resolved occurrence
    http.Delete ->
      case try_reopen_occurrence(req, ctx, occurrence_id) {
        Error(err) -> handle_error(err)
        Ok(body) -> wisp.json_response(body, 200)
      }

    _ -> wisp.method_not_allowed([http.Post, http.Delete])
  }
}

fn try_resolve_occurrence(
  req: wisp.Request,
  ctx: Context,
  occ_id: String,
) -> Result(String, ResolveOccurrenceError) {
  use _ <- result.try(
    user.extract_uuid(request: req, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AccessControl),
  )

  use target <- result.try(
    uuid.from_string(occ_id)
    |> result.replace_error(InvalidUuid(occ_id)),
  )

  use returned <- result.try(
    sql.resolve_occurrence(ctx.db, target)
    |> result.map_error(DataBase),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(OccurrenceNotFound(target)),
  )

  //   Broadcast to all assigned users ----------------------------------------
  let _ =
    occurrence.broadcast(
      ctx:,
      registry: group_registry.get_registry(ctx.registry_name),
      occurrence: row.id,
      message: msg.Domain(msg.OccurrenceResolved(
        id: row.id,
        when: row.resolved_at,
      )),
    )

  // RESPONSE
  let timestamp_json =
    json.nullable(row.resolved_at, fn(time) {
      timestamp.to_unix_seconds(time) |> json.float
    })

  json.to_string(
    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("resolved_at", timestamp_json),
      #("updated_at", json.float(timestamp.to_unix_seconds(row.updated_at))),
    ]),
  )
}

fn try_reopen_occurrence(
  req: wisp.Request,
  ctx: Context,
  occ_id: String,
) -> Result(String, ResolveOccurrenceError) {
  use _ <- result.try(
    user.extract_uuid(request: req, cookie_name: user.uuid_cookie_name)
    |> result.map_error(AccessControl),
  )

  use target <- result.try(
    uuid.from_string(occ_id)
    |> result.replace_error(InvalidUuid(occ_id)),
  )

  use returned <- result.try(
    sql.reopen_occurrence(ctx.db, target)
    |> result.map_error(DataBase),
  )

  use row <- result.map(
    list.first(returned.rows)
    |> result.replace_error(OccurrenceNotFound(target)),
  )

  //   Broadcast to all assigned users ----------------------------------------
  let _ =
    occurrence.broadcast(
      ctx:,
      registry: group_registry.get_registry(ctx.registry_name),
      occurrence: row.id,
      message: msg.Domain(msg.OccurrenceReopened(
        id: row.id,
        when: row.resolved_at,
      )),
    )

  let timestamp_json =
    json.nullable(row.resolved_at, fn(time) {
      timestamp.to_unix_seconds(time) |> json.float
    })

  json.to_string(
    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("resolved_at", timestamp_json),
      #("updated_at", json.float(timestamp.to_unix_seconds(row.updated_at))),
    ]),
  )
}

fn handle_error(err: ResolveOccurrenceError) -> wisp.Response {
  case err {
    AccessControl(err) -> user.handle_authentication_error(err)
    DataBase(err) -> web.handle_database_error(err)
    InvalidUuid(id) ->
      wisp.bad_request("Ocorrência possui Uuid inválido: " <> id)
    OccurrenceNotFound(occ_id) ->
      wisp.Text("Ocorrência não encontrada: " <> uuid.to_string(occ_id))
      |> wisp.set_body(wisp.not_found(), _)
  }
}
