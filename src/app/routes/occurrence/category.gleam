import app/routes/occurrence/sql

pub type OccurrenceCategory {
  MainCategory(sql.OccurrenceCategoryEnum)
  SubCategory(sql.OccurrenceSubcategoryEnum)
}

pub fn to_string(category: OccurrenceCategory) -> String {
  case category {
    MainCategory(main_category) ->
      case main_category {
        sql.Other -> "other"
        sql.TrafficAccident -> "traffic_accident"
        sql.Fire -> "fire"
        sql.MedicEmergency -> "medic_emergency"
      }

    SubCategory(sub_category) ->
      case sub_category {
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
      }
  }
}

pub fn from_string(category: String) -> Result(OccurrenceCategory, String) {
  case category {
    // Main occurrence categories
    "other" -> Ok(MainCategory(sql.Other))
    "traffic_accident" -> Ok(MainCategory(sql.TrafficAccident))
    "fire" -> Ok(MainCategory(sql.Fire))
    "medic_emergency" -> Ok(MainCategory(sql.MedicEmergency))

    // Main occurrence subcategories
    "injured_animal" -> Ok(SubCategory(sql.InjuredAnimal))
    "flood" -> Ok(SubCategory(sql.Flood))
    "tree_crash" -> Ok(SubCategory(sql.TreeCrash))
    "motorcycle_crash" -> Ok(SubCategory(sql.MotorcycleCrash))
    "rollover" -> Ok(SubCategory(sql.Rollover))
    "run_over" -> Ok(SubCategory(sql.RunOver))
    "collision" -> Ok(SubCategory(sql.Collision))
    "vehicle" -> Ok(SubCategory(sql.Vehicle))
    "vegetation" -> Ok(SubCategory(sql.Vegetation))
    "comercial" -> Ok(SubCategory(sql.Comercial))
    "residential" -> Ok(SubCategory(sql.Residential))
    "intoxication" -> Ok(SubCategory(sql.Intoxication))
    "serious_injury" -> Ok(SubCategory(sql.SeriousInjury))
    "seizure" -> Ok(SubCategory(sql.Seizure))
    "heart_stop" -> Ok(SubCategory(sql.HeartStop))

    other -> Error(other)
  }
}
