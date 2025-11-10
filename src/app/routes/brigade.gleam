import app/routes/brigade/sql
import app/web/context.{type Context}
import gleam/bool
import gleam/erlang/process
import gleam/list
import gleam/result
import group_registry
import pog
import youid/uuid

import app/web/socket/message as msg

///   Notify an user that they were assigned to a brigade
pub fn notify_user_assignment(
  assigned user_id: uuid.Uuid,
  to brigade_id: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(msg.ServerMessage),
) -> Nil {
  let members = group_registry.members(registry, uuid.to_string(user_id))

  list.each(members, fn(member) {
    let msg = msg.UserAssignedToBrigade(user_id:, brigade_id:)
    process.send(member, msg)
  })
}

///   Call `notify_user_assignment` on multiple users
pub fn broadcast_assignments(
  assigned_members id_list: List(uuid.Uuid),
  to brigade_id: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(msg.ServerMessage),
) -> Nil {
  list.each(id_list, fn(id) { notify_user_assignment(id, brigade_id, registry) })
}

pub fn broadcast(
  ctx ctx: Context,
  registry registry: group_registry.GroupRegistry(msg.ServerMessage),
  brigade brigade_id: uuid.Uuid,
  body body: String,
) -> Result(Nil, pog.QueryError) {
  use <- bool.guard(when: body == "", return: Ok(Nil))
  use returned <- result.map(sql.query_members_id(ctx.conn, brigade_id))
  use row <- list.each(returned.rows)

  let user_id = row.id
  let members = group_registry.members(registry, uuid.to_string(user_id))

  use member <- list.each(members)
  process.send(member, msg.Broadcast(body))
}
