import gleam/dynamic/decode

pub type Priority {
  High
  Medium
  Low
}

pub fn to_string(value: Priority) {
  case value {
    High -> "high"
    Low -> "low"
    Medium -> "medium"
  }
}

pub fn to_string_pt_br(value: Priority) {
  case value {
    High -> "alta"
    Low -> "baixa"
    Medium -> "média"
  }
}

pub fn from_string(maybe_priority: String) -> Result(Priority, Nil) {
  case maybe_priority {
    "high" -> Ok(High)
    "medium" -> Ok(Medium)
    "low" -> Ok(Low)

    _ -> Error(Nil)
  }
}

pub fn from_string_pt_br(maybe_priority: String) -> Result(Priority, Nil) {
  case maybe_priority {
    "alta" -> Ok(High)
    "média" -> Ok(Medium)
    "baixa" -> Ok(Low)

    _ -> Error(Nil)
  }
}

pub fn decoder() {
  use prioriry_string <- decode.then(decode.string)
  case from_string(prioriry_string) {
    Error(_) -> decode.failure(Low, "prioridade")
    Ok(value) -> decode.success(value)
  }
}
