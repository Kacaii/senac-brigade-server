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

pub fn from_string(maybe_category: String) -> Result(Category, String) {
  case maybe_category {
    "traffic_accident" -> Ok(TrafficAccident)
    "fire" -> Ok(Fire)
    "medic_emergency" -> Ok(MedicEmergency)
    "other" -> Ok(Other)

    unkown -> Error(unkown)
  }
}
