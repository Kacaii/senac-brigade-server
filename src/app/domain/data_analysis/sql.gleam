//// This module contains the code to run the sql queries defined in
//// `./src/app/domain/data_analysis/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `occurrence_dataset` query
/// defined in `./src/app/domain/data_analysis/sql/occurrence_dataset.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type OccurrenceDatasetRow {
  OccurrenceDatasetRow(
    occurrence_id: Uuid,
    reported_timestamp: Timestamp,
    arrival_timestamp: Option(Timestamp),
    resolved_timestamp: Option(Timestamp),
    occurrence_category: OccurrenceCategoryEnum,
    occurrence_subcategory: Option(OccurrenceSubcategoryEnum),
    priority: OccurrencePriorityEnum,
    applicant_name: Option(String),
    applicant_role: Option(UserRoleEnum),
    latitude: Float,
    longitude: Float,
  )
}

/// 󰕮  Occurrence reports
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn occurrence_dataset(
  db: pog.Connection,
) -> Result(pog.Returned(OccurrenceDatasetRow), pog.QueryError) {
  let decoder = {
    use occurrence_id <- decode.field(0, uuid_decoder())
    use reported_timestamp <- decode.field(1, pog.timestamp_decoder())
    use arrival_timestamp <- decode.field(
      2,
      decode.optional(pog.timestamp_decoder()),
    )
    use resolved_timestamp <- decode.field(
      3,
      decode.optional(pog.timestamp_decoder()),
    )
    use occurrence_category <- decode.field(
      4,
      occurrence_category_enum_decoder(),
    )
    use occurrence_subcategory <- decode.field(
      5,
      decode.optional(occurrence_subcategory_enum_decoder()),
    )
    use priority <- decode.field(6, occurrence_priority_enum_decoder())
    use applicant_name <- decode.field(7, decode.optional(decode.string))
    use applicant_role <- decode.field(
      8,
      decode.optional(user_role_enum_decoder()),
    )
    use latitude <- decode.field(9, decode.float)
    use longitude <- decode.field(10, decode.float)
    decode.success(OccurrenceDatasetRow(
      occurrence_id:,
      reported_timestamp:,
      arrival_timestamp:,
      resolved_timestamp:,
      occurrence_category:,
      occurrence_subcategory:,
      priority:,
      applicant_name:,
      applicant_role:,
      latitude:,
      longitude:,
    ))
  }

  "-- 󰕮  Occurrence reports
select
    o.id as occurrence_id,
    o.created_at as reported_timestamp,
    o.arrived_at as arrival_timestamp,
    o.resolved_at as resolved_timestamp,
    o.occurrence_category,
    o.occurrence_subcategory,
    o.priority,
    u_applicant.full_name as applicant_name,
    u_applicant.user_role as applicant_role,
    o.occurrence_location[1] as latitude,
    o.occurrence_location[2] as longitude
from
    public.occurrence as o
left join
    public.user_account as u_applicant
    on o.applicant_id = u_applicant.id
order by
    o.created_at desc;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `occurrence_category_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type OccurrenceCategoryEnum {
  Other
  TrafficAccident
  Fire
  MedicEmergency
}

fn occurrence_category_enum_decoder() -> decode.Decoder(OccurrenceCategoryEnum) {
  use occurrence_category_enum <- decode.then(decode.string)
  case occurrence_category_enum {
    "other" -> decode.success(Other)
    "traffic_accident" -> decode.success(TrafficAccident)
    "fire" -> decode.success(Fire)
    "medic_emergency" -> decode.success(MedicEmergency)
    _ -> decode.failure(Other, "OccurrenceCategoryEnum")
  }
}/// Corresponds to the Postgres `occurrence_priority_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type OccurrencePriorityEnum {
  High
  Medium
  Low
}

fn occurrence_priority_enum_decoder() -> decode.Decoder(OccurrencePriorityEnum) {
  use occurrence_priority_enum <- decode.then(decode.string)
  case occurrence_priority_enum {
    "high" -> decode.success(High)
    "medium" -> decode.success(Medium)
    "low" -> decode.success(Low)
    _ -> decode.failure(High, "OccurrencePriorityEnum")
  }
}/// Corresponds to the Postgres `occurrence_subcategory_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type OccurrenceSubcategoryEnum {
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

fn occurrence_subcategory_enum_decoder() -> decode.Decoder(OccurrenceSubcategoryEnum) {
  use occurrence_subcategory_enum <- decode.then(decode.string)
  case occurrence_subcategory_enum {
    "injured_animal" -> decode.success(InjuredAnimal)
    "flood" -> decode.success(Flood)
    "tree_crash" -> decode.success(TreeCrash)
    "motorcycle_crash" -> decode.success(MotorcycleCrash)
    "rollover" -> decode.success(Rollover)
    "run_over" -> decode.success(RunOver)
    "collision" -> decode.success(Collision)
    "vehicle" -> decode.success(Vehicle)
    "vegetation" -> decode.success(Vegetation)
    "comercial" -> decode.success(Comercial)
    "residential" -> decode.success(Residential)
    "intoxication" -> decode.success(Intoxication)
    "serious_injury" -> decode.success(SeriousInjury)
    "seizure" -> decode.success(Seizure)
    "pre_hospital_care" -> decode.success(PreHospitalCare)
    "heart_stop" -> decode.success(HeartStop)
    _ -> decode.failure(InjuredAnimal, "OccurrenceSubcategoryEnum")
  }
}/// Corresponds to the Postgres `user_role_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UserRoleEnum {
  Sargeant
  Developer
  Captain
  Firefighter
  Analyst
  Admin
}

fn user_role_enum_decoder() -> decode.Decoder(UserRoleEnum) {
  use user_role_enum <- decode.then(decode.string)
  case user_role_enum {
    "sargeant" -> decode.success(Sargeant)
    "developer" -> decode.success(Developer)
    "captain" -> decode.success(Captain)
    "firefighter" -> decode.success(Firefighter)
    "analyst" -> decode.success(Analyst)
    "admin" -> decode.success(Admin)
    _ -> decode.failure(Sargeant, "UserRoleEnum")
  }
}

// --- Encoding/decoding utils -------------------------------------------------

/// A decoder to decode `Uuid`s coming from a Postgres query.
///
fn uuid_decoder() {
  use bit_array <- decode.then(decode.bit_array)
  case uuid.from_bit_array(bit_array) {
    Ok(uuid) -> decode.success(uuid)
    Error(_) -> decode.failure(uuid.v7(), "Uuid")
  }
}
