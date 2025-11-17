import app/domain/occurrence/category
import gleam/option
import gleam/time/timestamp
import youid/uuid

/// 󱔔  Message broadcasted to all active users
pub type Msg {
  ///   Everyone replies with pong! Useful for checking active connections
  Ping
  /// 󱥁  Broadcast a text message
  Broadcast(String)
  /// 󰢫  Broadcast a domain-specific event related to SIGO's business logic
  Domain(DomainEvent)
  ///   Broadcast a event related to private channels
  Channel(ChannelEvent)
}

/// 󰢫  Domain-level events emitted when something meaningful happens in the system
pub type DomainEvent {
  /// 󰿄  An user has been assigned to a brigade
  UserAssignedToBrigade(user_id: uuid.Uuid, brigade_id: uuid.Uuid)
  /// 󰿄  A brigade member has been assigned to an occurrence
  UserAssignedToOccurrence(user_id: uuid.Uuid, occurrence_id: uuid.Uuid)
  ///   A new occurrence has been created
  OccurrenceCreated(id: uuid.Uuid, category: category.Category)
  ///   An occurrence has been marked as resolved
  OccurrenceResolved(id: uuid.Uuid, when: option.Option(timestamp.Timestamp))
  ///   A previously resolved occurrence has been reopened
  OccurrenceReopened(id: uuid.Uuid, when: option.Option(timestamp.Timestamp))
}

///   Channel-scoped events for private communication groups
/// Users can join and leave channels dynamically, allowing target websockets broadcasts
pub type ChannelEvent {
  /// 󰿄  The client requsts to join a private channel
  Join(channel_id: uuid.Uuid)
  /// 󰿅  The client requsts to leave a private channel
  Leave(channel_id: uuid.Uuid)
}
