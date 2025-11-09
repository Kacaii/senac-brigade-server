import app/web/context
import gleam/erlang/process
import gleam/list
import group_registry
import youid/uuid

///   Notify an user that they were assigned to a brigade
pub fn notify_user_assigned(
  assigned user_id: uuid.Uuid,
  to brigade_id: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(context.ServerMessage),
) -> Nil {
  let members = group_registry.members(registry, uuid.to_string(user_id))
  list.each(members, fn(member) {
    let msg = context.UserAssignedToBrigade(user_id:, brigade_id:)
    process.send(member, msg)
  })
}
