import app/routes/occurrence/category
import gleam/option
import gleam/time/timestamp
import youid/uuid

/// 󱔔  Message broadcasted to all active users
pub type Msg {
  /// 󱥁  Broadcast a text message
  Broadcast(String)
  /// 󰿄  User was assigned to a brigade
  UserAssignedToBrigade(user_id: uuid.Uuid, brigade_id: uuid.Uuid)
  /// 󰿄  Member of a brigade was assigned to a occurrence
  UserAssignedToOccurrence(user_id: uuid.Uuid, occurrence_id: uuid.Uuid)
  ///   A new occurrence has been created
  NewOccurrence(occ_id: uuid.Uuid, occ_type: category.Category)
  /// TODO
  OccurrenceResolved(
    occ_id: uuid.Uuid,
    when: option.Option(timestamp.Timestamp),
  )
  ///   Everyone replies with pong! Useful for checking active connections
  Ping
}
