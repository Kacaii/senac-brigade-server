import app/routes/occurrence
import app/routes/occurrence/sql
import app/web
import app/web/context.{type Context}
import app/web/socket/message as msg
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result.{try}
import gleam/time/timestamp
import pog
import wisp
import youid/uuid

type ResolveOccurrenceError {
  InvalidUuid(String)
  OccurrenceNotFound(uuid.Uuid)
  DataBaseError(pog.QueryError)
}

pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
  id occurrence_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Put)

  case try_resolve_occurrence(ctx, occurrence_id) {
    Error(err) -> handle_error(err)
    Ok(data) -> handle_body(data)
  }
}

fn handle_body(data: json.Json) -> wisp.Response {
  todo
}

//   Zig:     const gamer = try bagulho()
//
//   gleam:   let gamer = result.try(bagulho())
//   gleam:   let gamer = try(bagulho())

fn try_resolve_occurrence(ctx: Context, occ_id: String) {
  let update_result = {
    use target <- try(
      uuid.from_string(occ_id)
      |> result.replace_error(InvalidUuid(occ_id)),
    )
    use returned <- try(
      sql.resolve_occurrence(ctx.db, target)
      |> result.map_error(DataBaseError),
    )

    use row <- result.map(
      list.first(returned.rows)
      |> result.replace_error(OccurrenceNotFound(target)),
    )

    let timestamp_json =
      json.nullable(row.resolved_at, fn(time) {
        timestamp.to_unix_seconds(time) |> json.float
      })

    occurrence.broadcast(
      ctx:,
      registry:,
      occ_id: row.id,
      message: msg.OccurrenceResolved(occ_id: row.id, when: row.resolved_at),
    )

    json.object([
      #("id", json.string(uuid.to_string(row.id))),
      #("resolved_at", timestamp_json),
    ])
  }
}

fn handle_error(err: ResolveOccurrenceError) -> wisp.Response {
  case err {
    DataBaseError(err) -> web.handle_database_error(err)
    InvalidUuid(_) -> todo
    OccurrenceNotFound(_) -> todo
  }
}
