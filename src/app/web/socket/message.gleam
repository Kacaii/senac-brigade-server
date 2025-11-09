import youid/uuid

pub type ServerMessage {
  Broadcast(String)
  UserAssignedToBrigade(user_id: uuid.Uuid, brigade_id: uuid.Uuid)
  UserAssignedToOccurrence(user_id: uuid.Uuid, occurrence_id: uuid.Uuid)
  Ping
}
