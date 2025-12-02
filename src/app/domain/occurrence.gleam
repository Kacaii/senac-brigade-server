import app/domain/occurrence/category
import app/domain/occurrence/sql
import app/domain/user
import app/web/context.{type Context}
import app/web/socket/message as msg
import gleam/erlang/process
import gleam/list
import gleam/result
import group_registry
import pog
import youid/uuid

/// 󱜠  Broadcast a message to all users assigned to a occurrence
pub fn broadcast(
  ctx ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.Msg),
  occurrence occ_id: uuid.Uuid,
  message message: msg.Msg,
) -> Result(Nil, pog.QueryError) {
  use returned <- result.map(sql.query_participants(ctx.db, occ_id))

  use row <- list.each(returned.rows)
  process.spawn(fn() { user.broadcast(registry, row.user_id, message) })
}

///   Notify subscribed users that a new occurrence has been added
pub fn notify_new_occurrence(
  registry registry: group_registry.GroupRegistry(msg.Msg),
  new id: uuid.Uuid,
  of category: category.Category,
) -> Nil {
  let topic = "occurrence:new_" <> category.to_string(category)
  let members = group_registry.members(registry, topic)

  use subject <- list.each(members)
  process.spawn(fn() {
    msg.Domain(msg.OccurrenceCreated(id:, category:))
    |> process.send(subject, _)
  })
}
