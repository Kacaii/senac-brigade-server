//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/occurrence/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

///   Inserts a new occurrence into the database
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_new_occurence(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
  arg_3: Uuid,
  arg_4: String,
  arg_5: List(Float),
  arg_6: String,
  arg_7: String,
  arg_8: List(Uuid),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "--   Inserts a new occurrence into the database
INSERT INTO public.occurrence (
    applicant_id,
    category_id,
    subcategory_id,
    description,
    location,
    reference_point,
    vehicle_code,
    participants_id
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8);
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.parameter(pog.text(uuid.to_string(arg_3)))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.array(fn(value) { pog.float(value) }, arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(
    pog.array(fn(value) { pog.text(uuid.to_string(value)) }, arg_8),
  )
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_occurences_by_applicant` query
/// defined in `./src/app/routes/occurrence/sql/query_occurences_by_applicant.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryOccurencesByApplicantRow {
  QueryOccurencesByApplicantRow(
    id: Uuid,
    description: Option(String),
    category: Option(String),
    subcategory: Option(String),
    created_at: Option(Timestamp),
    resolved_at: Option(Timestamp),
    location: List(Float),
    reference_point: Option(String),
  )
}

///   Retrieves all occurrences associated with a user,
/// including detailed category information and resolution status.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_occurences_by_applicant(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryOccurencesByApplicantRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.optional(decode.string))
    use category <- decode.field(2, decode.optional(decode.string))
    use subcategory <- decode.field(3, decode.optional(decode.string))
    use created_at <- decode.field(4, decode.optional(pog.timestamp_decoder()))
    use resolved_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use location <- decode.field(6, decode.list(decode.float))
    use reference_point <- decode.field(7, decode.optional(decode.string))
    decode.success(QueryOccurencesByApplicantRow(
      id:,
      description:,
      category:,
      subcategory:,
      created_at:,
      resolved_at:,
      location:,
      reference_point:,
    ))
  }

  "--   Retrieves all occurrences associated with a user,
-- including detailed category information and resolution status.
SELECT
    o.id,
    o.description,
    oc_cat.category_name AS category,
    sub_cat.category_name AS subcategory,
    o.created_at,
    o.resolved_at,
    o.location,
    o.reference_point
FROM public.query_all_ocurrences_by_user_id($1) AS oc_list (id)
INNER JOIN public.occurrence AS o
    ON oc_list.id = o.id
LEFT JOIN public.occurrence_category AS oc_cat
    ON o.category_id = oc_cat.id
LEFT JOIN public.occurrence_category AS sub_cat
    ON o.subcategory_id = sub_cat.id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_recent_occurrences` query
/// defined in `./src/app/routes/occurrence/sql/query_recent_occurrences.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryRecentOccurrencesRow {
  QueryRecentOccurrencesRow(
    id: Uuid,
    created_at: Option(Timestamp),
    description: Option(String),
    category: Option(String),
    subcategory: Option(String),
    location: List(Float),
    reference_point: Option(String),
  )
}

///   Find all occurrences from the last 24 hours
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_recent_occurrences(
  db: pog.Connection,
) -> Result(pog.Returned(QueryRecentOccurrencesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use created_at <- decode.field(1, decode.optional(pog.timestamp_decoder()))
    use description <- decode.field(2, decode.optional(decode.string))
    use category <- decode.field(3, decode.optional(decode.string))
    use subcategory <- decode.field(4, decode.optional(decode.string))
    use location <- decode.field(5, decode.list(decode.float))
    use reference_point <- decode.field(6, decode.optional(decode.string))
    decode.success(QueryRecentOccurrencesRow(
      id:,
      created_at:,
      description:,
      category:,
      subcategory:,
      location:,
      reference_point:,
    ))
  }

  "--   Find all occurrences from the last 24 hours
SELECT
    oc.id,
    oc.created_at,
    oc.description,
    oc_cat.category_name AS category,
    sub_cat.category_name AS subcategory,
    oc.location,
    oc.reference_point
FROM public.occurrence AS oc
LEFT JOIN public.occurrence_category AS oc_cat
    ON oc.category_id = oc_cat.id
LEFT JOIN public.occurrence_category AS sub_cat
    ON oc.subcategory_id = sub_cat.id
WHERE oc.created_at >= (NOW() - '1 day'::INTERVAL);
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
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
