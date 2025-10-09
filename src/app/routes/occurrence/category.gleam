import app/routes/occurrence/sql
import gleam/string

pub fn category_to_string(category: sql.OccurrenceCategoryEnum) -> String {
  case category {
    sql.Other -> "other"
    sql.TrafficAccident -> "traffic_accident"
    sql.Fire -> "fire"
    sql.MedicEmergency -> "medic_emergency"
  }
}

pub fn subcategory_to_string(category: sql.OccurrenceSubcategoryEnum) -> String {
  case category {
    sql.InjuredAnimal -> "injured_animal"
    sql.Flood -> "flood"
    sql.TreeCrash -> "tree_crash"
    sql.MotorcycleCrash -> "motorcycle_crash"
    sql.Rollover -> "rollover"
    sql.RunOver -> "run_over"
    sql.Collision -> "collision"
    sql.Vehicle -> "vehicle"
    sql.Vegetation -> "vegetation"
    sql.Comercial -> "comercial"
    sql.Residential -> "residential"
    sql.Intoxication -> "intoxication"
    sql.SeriousInjury -> "serious_injury"
    sql.Seizure -> "seizure"
    sql.HeartStop -> "heart_stop"
    sql.PreHospitalCare -> "pre_hospital_care"
  }
}

pub fn main_category_from_string(
  category: String,
) -> Result(sql.OccurrenceCategoryEnum, String) {
  case string.lowercase(category) {
    // Main occurrence categories ----------------------------------------------
    "other" -> Ok(sql.Other)
    "traffic_accident" -> Ok(sql.TrafficAccident)
    "fire" -> Ok(sql.Fire)
    "medic_emergency" -> Ok(sql.MedicEmergency)

    // Fallback
    unknown -> Error(unknown)
  }
}

pub fn sub_category_from_string(
  category: String,
) -> Result(sql.OccurrenceSubcategoryEnum, String) {
  case string.lowercase(category) {
    "injured_animal" -> Ok(sql.InjuredAnimal)
    "flood" -> Ok(sql.Flood)
    "tree_crash" -> Ok(sql.TreeCrash)
    "motorcycle_crash" -> Ok(sql.MotorcycleCrash)
    "rollover" -> Ok(sql.Rollover)
    "run_over" -> Ok(sql.RunOver)
    "collision" -> Ok(sql.Collision)
    "vehicle" -> Ok(sql.Vehicle)
    "vegetation" -> Ok(sql.Vegetation)
    "comercial" -> Ok(sql.Comercial)
    "residential" -> Ok(sql.Residential)
    "intoxication" -> Ok(sql.Intoxication)
    "serious_injury" -> Ok(sql.SeriousInjury)
    "seizure" -> Ok(sql.Seizure)
    "heart_stop" -> Ok(sql.HeartStop)
    "pre_hospital_care" -> Ok(sql.PreHospitalCare)

    // Fallback
    unknown -> Error(unknown)
  }
}
