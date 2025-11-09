import app/web/context
import gleam/erlang/process
import gleam/json
import gleam/list
import group_registry
import youid/uuid

/// Notify an user that they were assigned to a brigade
pub fn notify_member_assignment(
  assigned member: uuid.Uuid,
  to brigade: uuid.Uuid,
  registry registry: group_registry.GroupRegistry(context.ServerMessage),
) -> Nil {
  // Build notification
  let data_type = "assigned_brigade_member" |> json.string
  let member_json = uuid.to_string(member) |> json.string
  let brigade_json = uuid.to_string(brigade) |> json.string

  // Construct the body
  let body =
    json.object([
      #("type", data_type),
      #("user_id", member_json),
      #("brigade_id", brigade_json),
    ])

  // Broadcast
  let members = group_registry.members(registry, uuid.to_string(member))
  list.each(members, fn(member) {
    let msg = context.Broadcast(json.to_string(body))
    process.send(member, msg)
  })
}
