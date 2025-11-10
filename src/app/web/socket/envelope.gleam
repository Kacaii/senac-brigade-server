import gleam/json
import gleam/time/timestamp
import youid/uuid

/// 󰛮  Wrapper for data sent a websocket connection
pub type Envelope {
  Envelope(data_type: String, data: json.Json, meta: MetaData)
}

///   Metadata for the envelope
pub type MetaData {
  MetaData(timestamp: timestamp.Timestamp, request_id: uuid.Uuid)
}

///   Converts a envelope to a json type
pub fn to_json(envelope: Envelope) -> json.Json {
  let Envelope(data_type:, data:, meta:) = envelope
  json.object([
    #("data_type", json.string(data_type)),
    #("data", data),
    #("meta", meta_data_to_json(meta)),
  ])
}

fn meta_data_to_json(meta_data: MetaData) -> json.Json {
  let MetaData(timestamp:, request_id:) = meta_data
  json.object([
    #("timestamp", json.float(timestamp.to_unix_seconds(timestamp))),
    #("request_id", json.string(uuid.to_string(request_id))),
  ])
}
