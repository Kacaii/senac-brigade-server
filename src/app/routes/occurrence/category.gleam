import gleam/dynamic/decode
import gleam/string

pub type Category {
  Other
  TrafficAccident
  Fire
  MedicEmergency
}

pub fn to_string(category: Category) {
  case category {
    Other -> "other"
    TrafficAccident -> "traffic_accident"
    Fire -> "fire"
    MedicEmergency -> "medic_emergency"
  }
}

pub fn to_string_pt_br(category: Category) {
  case category {
    Fire -> "incêndio"
    MedicEmergency -> "emergência médica"
    Other -> "outros"
    TrafficAccident -> "acidente de trânsito"
  }
}

pub fn from_string(maybe_category: String) -> Result(Category, String) {
  case string.lowercase(maybe_category) {
    "traffic_accident" -> Ok(TrafficAccident)
    "fire" -> Ok(Fire)
    "medic_emergency" -> Ok(MedicEmergency)
    "other" -> Ok(Other)

    unkown -> Error(unkown)
  }
}

pub fn from_string_pt_br(maybe_category: String) {
  case string.lowercase(maybe_category) {
    "incêndio" -> Ok(Fire)
    "acidente de trânsito" -> Ok(TrafficAccident)
    "emergência médica" -> Ok(MedicEmergency)
    "outros" -> Ok(Other)

    unkown -> Error(unkown)
  }
}

pub fn decoder() -> decode.Decoder(Category) {
  use category_string <- decode.then(decode.string)
  case from_string(category_string) {
    Error(_) -> decode.failure(Other, "categoria")
    Ok(value) -> decode.success(value)
  }
}
