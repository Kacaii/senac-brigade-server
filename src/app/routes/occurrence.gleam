import youid/uuid

pub type Occurrence {
  Occurrence(
    occurrence_category: Category,
    occurrence_subcategory: Subcategory,
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
    participants_id: List(uuid.Uuid),
  )
}

pub type Category {
  Other
  TrafficAccident
  Fire
  MedicEmergency
}

pub type Subcategory {
  InjuredAnimal
  Flood
  TreeCrash
  MotorcycleCrash
  Rollover
  RunOver
  Collision
  Vehicle
  Vegetation
  Comercial
  Residential
  Intoxication
  SeriousInjury
  Seizure
  PreHospitalCare
  HeartStop
}

pub fn category_to_string(category: Category) {
  case category {
    Other -> "other"
    TrafficAccident -> "traffic_accident"
    Fire -> "fire"
    MedicEmergency -> "medic_emergency"
  }
}

pub fn category_from_string(maybe_category: String) -> Result(Category, String) {
  case maybe_category {
    "traffic_accident" -> Ok(TrafficAccident)
    "fire" -> Ok(Fire)
    "medic_emergency" -> Ok(MedicEmergency)
    "other" -> Ok(Other)

    unkown -> Error(unkown)
  }
}

pub fn subcategory_to_string(subcategory: Subcategory) -> String {
  case subcategory {
    InjuredAnimal -> "injured_animal"
    Flood -> "flood"
    TreeCrash -> "tree_crash"
    MotorcycleCrash -> "motorcycle_crash"
    Rollover -> "rollover"
    RunOver -> "run_over"
    Collision -> "collision"
    Vehicle -> "vehicle"
    Vegetation -> "vegetation"
    Comercial -> "comercial"
    Residential -> "residential"
    Intoxication -> "intoxication"
    SeriousInjury -> "serious_injury"
    Seizure -> "seizure"
    HeartStop -> "heart_stop"
    PreHospitalCare -> "pre_hospital_care"
  }
}

pub fn subcategory_from_string(
  maybe_subcategory: String,
) -> Result(Subcategory, String) {
  case maybe_subcategory {
    "injured_animal" -> Ok(InjuredAnimal)
    "flood" -> Ok(Flood)
    "tree_crash" -> Ok(TreeCrash)
    "motorcycle_crash" -> Ok(MotorcycleCrash)
    "rollover" -> Ok(Rollover)
    "run_over" -> Ok(RunOver)
    "collision" -> Ok(Collision)
    "vehicle" -> Ok(Vehicle)
    "vegetation" -> Ok(Vegetation)
    "comercial" -> Ok(Comercial)
    "residential" -> Ok(Residential)
    "intoxication" -> Ok(Intoxication)
    "serious_injury" -> Ok(SeriousInjury)
    "seizure" -> Ok(Seizure)
    "heart_stop" -> Ok(HeartStop)
    "pre_hospital_care" -> Ok(PreHospitalCare)

    unknown -> Error(unknown)
  }
}
