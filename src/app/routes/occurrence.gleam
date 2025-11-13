import app/routes/occurrence/category
import app/routes/occurrence/sql
import app/web/context.{type Context}
import app/web/socket
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

  let user_id = row.user_id
  let members = group_registry.members(registry, uuid.to_string(user_id))

  use member <- list.each(members)
  process.send(member, message)
}

///   Call `notify_user_assignment` on multiple users
pub fn broadcast_assignments(
  registry registry: group_registry.GroupRegistry(msg.Msg),
  assigned_users id_list: List(uuid.Uuid),
  to occurrence_id: uuid.Uuid,
) -> Nil {
  use id <- list.each(id_list)
  notify_user_assignment(assigned: id, to: occurrence_id, registry:)
}

///   Notify a member that their brigade was assigned to an occurrence.
pub fn notify_user_assignment(
  registry registry: group_registry.GroupRegistry(msg.Msg),
  assigned id: uuid.Uuid,
  to occ: uuid.Uuid,
) -> Nil {
  let members = group_registry.members(registry, uuid.to_string(id))
  use subject <- list.each(members)
  process.send(subject, msg.UserAssignedToOccurrence(assigned: id, to: occ))
}

///   Notify subscribed users that a new occurrence has been added
pub fn notify_new_occurrence(
  registry registry: group_registry.GroupRegistry(msg.Msg),
  new id: uuid.Uuid,
  of category: category.Category,
) -> Nil {
  let members = group_registry.members(registry, socket.ws_topic)
  use subject <- list.each(members)
  process.send(subject, msg.NewOccurrence(id:, category:))
}
