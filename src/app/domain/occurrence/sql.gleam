//// This module contains the code to run the sql queries defined in
//// `./src/app/domain/occurrence/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `assign_brigades_to_occurrence` query
/// defined in `./src/app/domain/occurrence/sql/assign_brigades_to_occurrence.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type AssignBrigadesToOccurrenceRow {
  AssignBrigadesToOccurrenceRow(inserted_brigade_id: Uuid)
}

///    Assign as list of brigades as participants of a occurrence
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn assign_brigades_to_occurrence(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: List(Uuid),
) -> Result(pog.Returned(AssignBrigadesToOccurrenceRow), pog.QueryError) {
  let decoder = {
    use inserted_brigade_id <- decode.field(0, uuid_decoder())
    decode.success(AssignBrigadesToOccurrenceRow(inserted_brigade_id:))
  }

  "--    Assign as list of brigades as participants of a occurrence
select ob.inserted_brigade_id
from public.assign_occurrence_brigades($1, $2) as ob;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(
    pog.array(fn(value) { pog.text(uuid.to_string(value)) }, arg_2),
  )
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_occurrence_by_id` query
/// defined in `./src/app/domain/occurrence/sql/delete_occurrence_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteOccurrenceByIdRow {
  DeleteOccurrenceByIdRow(id: Uuid)
}

///   Remove an occurrence from the database
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_occurrence_by_id(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(DeleteOccurrenceByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(DeleteOccurrenceByIdRow(id:))
  }

  "--   Remove an occurrence from the database
delete from public.occurrence as o
where o.id = $1
returning o.id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `insert_new_occurence` query
/// defined in `./src/app/domain/occurrence/sql/insert_new_occurence.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type InsertNewOccurenceRow {
  InsertNewOccurenceRow(
    id: Uuid,
    occurrence_category: OccurrenceCategoryEnum,
    priority: OccurrencePriorityEnum,
    applicant_id: Uuid,
    created_at: Timestamp,
  )
}

///   Inserts a new occurrence into the database
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
) -> Result(pog.Returned(InsertNewOccurenceRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use occurrence_category <- decode.field(
      1,
      occurrence_category_enum_decoder(),
    )
    use priority <- decode.field(2, occurrence_priority_enum_decoder())
    use applicant_id <- decode.field(3, uuid_decoder())
    use created_at <- decode.field(4, pog.timestamp_decoder())
    decode.success(InsertNewOccurenceRow(
      id:,
      occurrence_category:,
      priority:,
      applicant_id:,
      created_at:,
    ))
  }

  "--   Inserts a new occurrence into the database
insert into public.occurrence as o (
    applicant_id,
    occurrence_category,
    occurrence_subcategory,
    priority,
    description,
    occurrence_location,
    reference_point
) values (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7
)
returning
    o.id,
    o.occurrence_category,
    o.priority,
    o.applicant_id,
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
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_occurences_by_applicant` query
/// defined in `./src/app/domain/occurrence/sql/query_occurences_by_applicant.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryOccurencesByApplicantRow {
  QueryOccurencesByApplicantRow(
    id: Uuid,
    resolved_at: Option(Timestamp),
    priority: OccurrencePriorityEnum,
    occurrence_category: OccurrenceCategoryEnum,
    occurrence_location: Option(List(Float)),
    details: Option(String),
    applicant_name: String,
    created_at: Timestamp,
    arrived_at: Option(Timestamp),
    applicant_registration: String,
    applicant_id: Uuid,
    brigade_list: String,
  )
}

///   Retrieves all occurrences associated with a user,
/// including detailed category information and resolution status.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_occurences_by_applicant(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryOccurencesByApplicantRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use resolved_at <- decode.field(1, decode.optional(pog.timestamp_decoder()))
    use priority <- decode.field(2, occurrence_priority_enum_decoder())
    use occurrence_category <- decode.field(
      3,
      occurrence_category_enum_decoder(),
    )
    use occurrence_location <- decode.field(
      4,
      decode.optional(decode.list(decode.float)),
    )
    use details <- decode.field(5, decode.optional(decode.string))
    use applicant_name <- decode.field(6, decode.string)
    use created_at <- decode.field(7, pog.timestamp_decoder())
    use arrived_at <- decode.field(8, decode.optional(pog.timestamp_decoder()))
    use applicant_registration <- decode.field(9, decode.string)
    use applicant_id <- decode.field(10, uuid_decoder())
    use brigade_list <- decode.field(11, decode.string)
    decode.success(QueryOccurencesByApplicantRow(
      id:,
      resolved_at:,
      priority:,
      occurrence_category:,
      occurrence_location:,
      details:,
      applicant_name:,
      created_at:,
      arrived_at:,
      applicant_registration:,
      applicant_id:,
      brigade_list:,
    ))
  }

  "--   Retrieves all occurrences associated with a user,
-- including detailed category information and resolution status.
select
    o.id,
    o.resolved_at,
    o.priority,
    o.occurrence_category,
    o.occurrence_location,
    o.description as details,
    u.full_name as applicant_name,
    o.created_at,
    o.arrived_at,
    u.registration as applicant_registration,
    o.applicant_id,

    (
        select json_agg(json_build_object(
            'id', b.id,
            'brigade_name', b.brigade_name,
            'leader_full_name', leader_u.full_name,
            'vehicle_code', b.vehicle_code
        )) from public.occurrence_brigade as ob
        inner join public.brigade as b
            on ob.brigade_id = b.id
        inner join public.user_account as leader_u
            on b.leader_id = leader_u.id
        where ob.occurrence_id = o.id
    ) as brigade_list

from public.occurrence as o
inner join public.user_account as u
    on o.applicant_id = u.id
where o.applicant_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_participants` query
/// defined in `./src/app/domain/occurrence/sql/query_participants.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryParticipantsRow {
  QueryParticipantsRow(user_id: Uuid)
}

/// 󰀖  Find all users that participated in a occurrence
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_participants(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryParticipantsRow), pog.QueryError) {
  let decoder = {
    use user_id <- decode.field(0, uuid_decoder())
    decode.success(QueryParticipantsRow(user_id:))
  }

  "-- 󰀖  Find all users that participated in a occurrence
select distinct participant.user_id
from public.brigade_membership as participant
inner join public.occurrence_brigade as ob
    on participant.brigade_id = ob.brigade_id
where ob.occurrence_id = $1
order by participant.user_id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_recent_occurrences` query
/// defined in `./src/app/domain/occurrence/sql/query_recent_occurrences.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryRecentOccurrencesRow {
  QueryRecentOccurrencesRow(
    id: Uuid,
    created_at: Timestamp,
    description: Option(String),
    occurrence_category: OccurrenceCategoryEnum,
    occurrence_subcategory: Option(OccurrenceSubcategoryEnum),
    occurrence_location: Option(List(Float)),
    reference_point: Option(String),
  )
}

///   Find all occurrences from the last 24 hours
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
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
    use occurrence_location <- decode.field(
      5,
      decode.optional(decode.list(decode.float)),
    )
    use reference_point <- decode.field(6, decode.optional(decode.string))
    decode.success(QueryRecentOccurrencesRow(
      id:,
      created_at:,
      description:,
      occurrence_category:,
      occurrence_subcategory:,
      occurrence_location:,
      reference_point:,
    ))
  }

  "--   Find all occurrences from the last 24 hours
select
    o.id,
    o.created_at,
    o.description,
    o.occurrence_category,
    o.occurrence_subcategory,
    o.occurrence_location,
    o.reference_point
from public.occurrence as o
where o.created_at >= (now() - '1 day'::interval);
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `reopen_occurrence` query
/// defined in `./src/app/domain/occurrence/sql/reopen_occurrence.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ReopenOccurrenceRow {
  ReopenOccurrenceRow(
    id: Uuid,
    resolved_at: Option(Timestamp),
    updated_at: Timestamp,
  )
}

/// 󰚰  Mark a occurrence as unresolved
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn reopen_occurrence(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(ReopenOccurrenceRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use resolved_at <- decode.field(1, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(2, pog.timestamp_decoder())
    decode.success(ReopenOccurrenceRow(id:, resolved_at:, updated_at:))
  }

  "-- 󰚰  Mark a occurrence as unresolved
update public.occurrence
set
    resolved_at = null,
    updated_at = current_timestamp
where id = $1
returning
    id,
    resolved_at,
    updated_at;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `replace_occurrence_brigades` query
/// defined in `./src/app/domain/occurrence/sql/replace_occurrence_brigades.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ReplaceOccurrenceBrigadesRow {
  ReplaceOccurrenceBrigadesRow(inserted_brigade_id: Uuid)
}

///   Replace all assigned brigades
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn replace_occurrence_brigades(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: List(Uuid),
) -> Result(pog.Returned(ReplaceOccurrenceBrigadesRow), pog.QueryError) {
  let decoder = {
    use inserted_brigade_id <- decode.field(0, uuid_decoder())
    decode.success(ReplaceOccurrenceBrigadesRow(inserted_brigade_id:))
  }

  "--   Replace all assigned brigades
select o.inserted_brigade_id
from public.assign_occurrence_brigades($1, $2) as o;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(
    pog.array(fn(value) { pog.text(uuid.to_string(value)) }, arg_2),
  )
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `resolve_occurrence` query
/// defined in `./src/app/domain/occurrence/sql/resolve_occurrence.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ResolveOccurrenceRow {
  ResolveOccurrenceRow(
    id: Uuid,
    resolved_at: Option(Timestamp),
    updated_at: Timestamp,
  )
}

/// 󰚰  Mark a occurrence as resolved
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn resolve_occurrence(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(ResolveOccurrenceRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use resolved_at <- decode.field(1, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(2, pog.timestamp_decoder())
    decode.success(ResolveOccurrenceRow(id:, resolved_at:, updated_at:))
  }

  "-- 󰚰  Mark a occurrence as resolved
update public.occurrence
set
    resolved_at = current_timestamp,
    updated_at = current_timestamp
where id = $1
returning
    id,
    resolved_at,
    updated_at;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
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
