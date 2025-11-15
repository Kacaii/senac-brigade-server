import app/routes/occurrence/category
import gleam/option
import gleam/time/timestamp
import youid/uuid

/// 󱔔  Message broadcasted to all active users
pub type Msg {
  ///   Everyone replies with pong! Useful for checking active connections
  Ping
  /// 󱥁  Broadcast a text message
  Broadcast(String)
  /// 󰿄  User was assigned to a brigade
  UserAssignedToBrigade(user_id: uuid.Uuid, brigade_id: uuid.Uuid)
  /// 󰿄  Member of a brigade was assigned to a occurrence
  UserAssignedToOccurrence(user_id: uuid.Uuid, occurrence_id: uuid.Uuid)
  ///   A new occurrence has been created
  NewOccurrence(id: uuid.Uuid, category: category.Category)
  ///   An occurrence has been marked as resolved
  OccurrenceResolved(id: uuid.Uuid, when: option.Option(timestamp.Timestamp))
  ///   An occurrence has been reopened
  OccurrenceReopened(id: uuid.Uuid, when: option.Option(timestamp.Timestamp))
  ///   Channel related commands
  ChannelCommand(ChannelMsg)
}

///   Users can join private channels
pub type ChannelMsg {
  /// 󰿄  Joins a channel
  Join(channel_id: uuid.Uuid)
  /// 󰿅  Exits a channel
  Leave(channel_id: uuid.Uuid)
}
