import app/web/socket/message as msg
import gleam/erlang/process
import gleam/list
import group_registry
import youid/uuid

///   Notify a member that their brigade was assigned to an occurrence.
pub fn notify_user_assignment(
  assigned user_id: uuid.Uuid,
  to occurrence_id: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(msg.ServerMessage),
) -> Nil {
  let members = group_registry.members(registry, uuid.to_string(user_id))

  list.each(members, fn(subject) {
    process.send(
      subject,
      msg.UserAssignedToOccurrence(user_id:, occurrence_id:),
    )
  })
}

///   Call `notify_user_assignment` on multiple users
pub fn broadcast_assignments(
  assigned_users id_list: List(uuid.Uuid),
  to occurrence_id: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(msg.ServerMessage),
) -> Nil {
  list.each(id_list, fn(id) {
    notify_user_assignment(assigned: id, to: occurrence_id, registry:)
  })
}
