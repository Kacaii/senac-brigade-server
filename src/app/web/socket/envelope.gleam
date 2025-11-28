import gleam/json
import gleam/time/timestamp
import youid/uuid

/// 󰛮  Wrapper for data sent through a websocket connection
pub type Envelope {
  Envelope(
    /// 󱤇  Used by the client to determine the type of message
    data_type: String,
    /// 󰏓  Payload of the message sent
    data: json.Json,
    /// 󱩼  Metadata aboute the package
    meta: MetaData,
  )
}

///   Metadata for the envelope type
pub type MetaData {
  MetaData(
    /// 󱎫  Timestamp of the moment the package was sent
    timestamp: timestamp.Timestamp,
    ///   User connected to the websocket
    request_id: uuid.Uuid,
  )
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
