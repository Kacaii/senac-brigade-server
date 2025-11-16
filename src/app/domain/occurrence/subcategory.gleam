import gleam/dynamic/decode
import gleam/string

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

pub fn to_string(subcategory: Subcategory) -> String {
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

pub fn to_string_pt_br(subcategory: Subcategory) -> String {
  case subcategory {
    InjuredAnimal -> "animal ferido"
    Flood -> "enchente"
    TreeCrash -> "árvore caída"
    MotorcycleCrash -> "acidente de moto"
    Rollover -> "capotamento"
    RunOver -> "atropelamento"
    Collision -> "colisão"
    Vehicle -> "veículo"
    Vegetation -> "vegetação"
    Comercial -> "comercial"
    Residential -> "residencial"
    Intoxication -> "intoxicação"
    SeriousInjury -> "ferimento grave"
    Seizure -> "convulsão"
    HeartStop -> "parada cardíaca"
    PreHospitalCare -> "aph"
  }
}

pub fn from_string(maybe_subcategory: String) -> Result(Subcategory, String) {
  case string.lowercase(maybe_subcategory) {
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

pub fn from_string_pt_br(
  maybe_subcategory: String,
) -> Result(Subcategory, String) {
  case string.lowercase(maybe_subcategory) {
    "animal ferido" -> Ok(InjuredAnimal)
    "enchente" -> Ok(Flood)
    "árvore caída" -> Ok(TreeCrash)
    "acidente de moto" -> Ok(MotorcycleCrash)
    "capotamento" -> Ok(Rollover)
    "atropelamento" -> Ok(RunOver)
    "colisão" -> Ok(Collision)
    "veículo" -> Ok(Vehicle)
    "vegetação" -> Ok(Vegetation)
    "comercial" -> Ok(Comercial)
    "residencial" -> Ok(Residential)
    "intoxicação" -> Ok(Intoxication)
    "ferimento grave" -> Ok(SeriousInjury)
    "convulsão" -> Ok(Seizure)
    "parada cardíaca" -> Ok(HeartStop)
    "aph" -> Ok(PreHospitalCare)

    unknown -> Error(unknown)
  }
}

pub fn decoder() {
  use subcategory_string <- decode.then(decode.string)
  case from_string(subcategory_string) {
    Error(_) -> decode.failure(Residential, "subcategoria")
    Ok(value) -> decode.success(value)
  }
}
