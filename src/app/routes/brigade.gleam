import gleam/erlang/process
import gleam/list
import group_registry
import youid/uuid

import app/web/socket/message as msg

///   Notify an user that they were assigned to a brigade
pub fn notify_user_assigned(
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
