import app/domain/brigade/sql
import app/domain/user
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
  use <- process.spawn
  user.broadcast(registry, row.id, message)
}
