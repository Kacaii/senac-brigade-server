import app/routes/brigade/sql
import app/web/context.{type Context}
import app/web/socket/message as msg
import gleam/erlang/process
import gleam/list
import gleam/result
import group_registry
import pog
import youid/uuid

/// 󱜠  Broadcast a message to all members assigned to a brigade
pub fn broadcast(
  ctx ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.Msg),
  brigade brigade_id: uuid.Uuid,
  message message: msg.Msg,
) -> Result(Nil, pog.QueryError) {
  use returned <- result.map(sql.query_members_id(ctx.db, brigade_id))
  use row <- list.each(returned.rows)

  let topic = "user:" <> uuid.to_string(row.id)
  let members = group_registry.members(registry, topic)

  use member <- list.each(members)
  process.send(member, message)
}

/// 󱥁  Notify an user that they were assigned to a brigade
pub fn notify_user_assignment(
  registry registry: group_registry.GroupRegistry(msg.Msg),
  assigned user_id: uuid.Uuid,
  to brigade_id: uuid.Uuid,
) -> Nil {
  let topic = "user:" <> uuid.to_string(user_id)
  let members = group_registry.members(registry, topic)

  use subject <- list.each(members)
  let msg = msg.UserAssignedToBrigade(assigned: user_id, to: brigade_id)
  process.send(subject, msg)
}

///   Call `notify_user_assignment` on multiple users
pub fn broadcast_assignments(
  registry registry: group_registry.GroupRegistry(msg.Msg),
  assigned_members user_id_list: List(uuid.Uuid),
  to brigade_id: uuid.Uuid,
) -> Nil {
  use user_id <- list.each(user_id_list)
  notify_user_assignment(registry:, assigned: user_id, to: brigade_id)
}
