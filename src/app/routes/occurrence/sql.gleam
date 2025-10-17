//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/occurrence/sql`.
//// > 🐿️ This module was generated automatically using v4.4.2 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `delete_occurence_by_id` query
/// defined in `./src/app/routes/occurrence/sql/delete_occurence_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteOccurenceByIdRow {
  DeleteOccurenceByIdRow(id: Uuid)
}

///   Remove an occurence from the database
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_occurence_by_id(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(DeleteOccurenceByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(DeleteOccurenceByIdRow(id:))
  }

  "--   Remove an occurence from the database
DELETE FROM public.occurrence AS o
WHERE o.id = $1
RETURNING o.id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `insert_new_occurence` query
/// defined in `./src/app/routes/occurrence/sql/insert_new_occurence.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type InsertNewOccurenceRow {
  InsertNewOccurenceRow(
    id: Uuid,
    priority: OccurrencePriorityEnum,
    applicant_id: Option(Uuid),
    brigade_id: Option(Uuid),
    created_at: Timestamp,
  )
}

///   Inserts a new occurrence into the database
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_new_occurence(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: OccurrenceCategoryEnum,
  arg_3: OccurrenceSubcategoryEnum,
  arg_4: OccurrencePriorityEnum,
  arg_5: String,
  arg_6: List(Float),
  arg_7: String,
  arg_8: String,
  arg_9: Uuid,
) -> Result(pog.Returned(InsertNewOccurenceRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use priority <- decode.field(1, occurrence_priority_enum_decoder())
    use applicant_id <- decode.field(2, decode.optional(uuid_decoder()))
    use brigade_id <- decode.field(3, decode.optional(uuid_decoder()))
    use created_at <- decode.field(4, pog.timestamp_decoder())
    decode.success(InsertNewOccurenceRow(
      id:,
      priority:,
      applicant_id:,
      brigade_id:,
      created_at:,
    ))
  }

  "--   Inserts a new occurrence into the database
INSERT INTO public.occurrence AS o (
    applicant_id,
    occurrence_category,
    occurrence_subcategory,
    priority,
    description,
    location,
    reference_point,
    vehicle_code,
    brigade_id
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8,
    $9
)
RETURNING
    o.id,
    o.priority,
    o.applicant_id,
    o.brigade_id,
    o.created_at;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(occurrence_category_enum_encoder(arg_2))
  |> pog.parameter(occurrence_subcategory_enum_encoder(arg_3))
  |> pog.parameter(occurrence_priority_enum_encoder(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.array(fn(value) { pog.float(value) }, arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.text(uuid.to_string(arg_9)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_occurences_by_applicant` query
/// defined in `./src/app/routes/occurrence/sql/query_occurences_by_applicant.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryOccurencesByApplicantRow {
  QueryOccurencesByApplicantRow(
    id: Uuid,
    occurrence_category: OccurrenceCategoryEnum,
    occurrence_subcategory: Option(OccurrenceSubcategoryEnum),
    priority: OccurrencePriorityEnum,
    description: Option(String),
    location: List(Float),
    reference_point: Option(String),
    created_at: Timestamp,
    updated_at: Timestamp,
    resolved_at: Option(Timestamp),
  )
}

///   Retrieves all occurrences associated with a user,
/// including detailed category information and resolution status.
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_occurences_by_applicant(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryOccurencesByApplicantRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use occurrence_category <- decode.field(
      1,
      occurrence_category_enum_decoder(),
    )
    use occurrence_subcategory <- decode.field(
      2,
      decode.optional(occurrence_subcategory_enum_decoder()),
    )
    use priority <- decode.field(3, occurrence_priority_enum_decoder())
    use description <- decode.field(4, decode.optional(decode.string))
    use location <- decode.field(5, decode.list(decode.float))
    use reference_point <- decode.field(6, decode.optional(decode.string))
    use created_at <- decode.field(7, pog.timestamp_decoder())
    use updated_at <- decode.field(8, pog.timestamp_decoder())
    use resolved_at <- decode.field(9, decode.optional(pog.timestamp_decoder()))
    decode.success(QueryOccurencesByApplicantRow(
      id:,
      occurrence_category:,
      occurrence_subcategory:,
      priority:,
      description:,
      location:,
      reference_point:,
      created_at:,
      updated_at:,
      resolved_at:,
    ))
  }

  "--   Retrieves all occurrences associated with a user,
-- including detailed category information and resolution status.
SELECT
    o.id,
    o.occurrence_category,
    o.occurrence_subcategory,
    o.priority,
    o.description,
    o.location,
    o.reference_point,
    o.created_at,
    o.updated_at,
    o.resolved_at
FROM public.query_all_occurrences_by_user_id($1) AS oc_list (id)
INNER JOIN public.occurrence AS o
    ON oc_list.id = o.id
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_recent_occurrences` query
/// defined in `./src/app/routes/occurrence/sql/query_recent_occurrences.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryRecentOccurrencesRow {
  QueryRecentOccurrencesRow(
    id: Uuid,
    created_at: Timestamp,
    description: Option(String),
    occurrence_category: OccurrenceCategoryEnum,
    occurrence_subcategory: Option(OccurrenceSubcategoryEnum),
    location: List(Float),
    reference_point: Option(String),
  )
}

///   Find all occurrences from the last 24 hours
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_recent_occurrences(
  db: pog.Connection,
) -> Result(pog.Returned(QueryRecentOccurrencesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use created_at <- decode.field(1, pog.timestamp_decoder())
    use description <- decode.field(2, decode.optional(decode.string))
    use occurrence_category <- decode.field(
      3,
      occurrence_category_enum_decoder(),
    )
    use occurrence_subcategory <- decode.field(
      4,
      decode.optional(occurrence_subcategory_enum_decoder()),
    )
    use location <- decode.field(5, decode.list(decode.float))
    use reference_point <- decode.field(6, decode.optional(decode.string))
    decode.success(QueryRecentOccurrencesRow(
      id:,
      created_at:,
      description:,
      occurrence_category:,
      occurrence_subcategory:,
      location:,
      reference_point:,
    ))
  }

  "--   Find all occurrences from the last 24 hours
SELECT
    o.id,
    o.created_at,
    o.description,
    o.occurrence_category,
    o.occurrence_subcategory,
    o.location,
    o.reference_point
FROM public.occurrence AS o
WHERE o.created_at >= (NOW() - '1 day'::INTERVAL);
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `occurrence_category_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
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
}

fn occurrence_category_enum_encoder(occurrence_category_enum) -> pog.Value {
  case occurrence_category_enum {
    Other -> "other"
    TrafficAccident -> "traffic_accident"
    Fire -> "fire"
    MedicEmergency -> "medic_emergency"
  }
  |> pog.text
}/// Corresponds to the Postgres `occurrence_priority_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
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
}

fn occurrence_priority_enum_encoder(occurrence_priority_enum) -> pog.Value {
  case occurrence_priority_enum {
    High -> "high"
    Medium -> "medium"
    Low -> "low"
  }
  |> pog.text
}/// Corresponds to the Postgres `occurrence_subcategory_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
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
}

fn occurrence_subcategory_enum_encoder(
  occurrence_subcategory_enum,
) -> pog.Value {
  case occurrence_subcategory_enum {
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
    PreHospitalCare -> "pre_hospital_care"
    HeartStop -> "heart_stop"
  }
  |> pog.text
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
