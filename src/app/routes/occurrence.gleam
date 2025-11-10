import app/routes/occurrence/sql
import app/web/context.{type Context}
import app/web/socket/message as msg
import gleam/bool
import gleam/erlang/process
import gleam/list
import gleam/result
import group_registry
import pog
import youid/uuid

/// 󱜠  Broadcast a text message to all users assigned to a occurrence
pub fn broadcast(
  ctx ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.ServerMessage),
  occurrence occ_id: uuid.Uuid,
  body body: String,
) -> Result(Nil, pog.QueryError) {
  use <- bool.guard(when: body == "", return: Ok(Nil))
  use returned <- result.map(sql.query_participants(ctx.db, occ_id))
  use row <- list.each(returned.rows)

  let user_id = row.user_id
  let members = group_registry.members(registry, uuid.to_string(user_id))

  use member <- list.each(members)
  process.send(member, msg.Broadcast(body))
}

///   Call `notify_user_assignment` on multiple users
pub fn broadcast_assignments(
  assigned_users id_list: List(uuid.Uuid),
  to occurrence_id: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(msg.ServerMessage),
) -> Nil {
  use id <- list.each(id_list)
  notify_user_assignment(assigned: id, to: occurrence_id, registry:)
}

///   Notify a member that their brigade was assigned to an occurrence.
pub fn notify_user_assignment(
  assigned user_id: uuid.Uuid,
  to occurrence_id: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(msg.ServerMessage),
) -> Nil {
  let members = group_registry.members(registry, uuid.to_string(user_id))

  use subject <- list.each(members)
  process.send(subject, msg.UserAssignedToOccurrence(user_id:, occurrence_id:))
}
