import youid/uuid

/// 󱔔  Message broadcasted to all active users
pub type ServerMessage {
  /// 󱥁  Broadcast a text message
  Broadcast(String)
  /// 󰿄  User was assigned to a brigade
  UserAssignedToBrigade(user_id: uuid.Uuid, brigade_id: uuid.Uuid)
  /// 󰿄  Member of a brigade was assigned to a occurrence
  UserAssignedToOccurrence(user_id: uuid.Uuid, occurrence_id: uuid.Uuid)
  ///   Everyone replies with pong! Useful to check connections.
  Ping
}
