//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/occurrence/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `count_active_occurrences` query
/// defined in `./src/app/routes/occurrence/sql/count_active_occurrences.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CountActiveOccurrencesRow {
  CountActiveOccurrencesRow(count: Int)
}

/// 󰆙  Counts the number of active occurrences
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn count_active_occurrences(
  db: pog.Connection,
) -> Result(pog.Returned(CountActiveOccurrencesRow), pog.QueryError) {
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(CountActiveOccurrencesRow(count:))
  }

  "-- 󰆙  Counts the number of active occurrences
SELECT COUNT(oc.id)
FROM public.occurrence AS oc
WHERE oc.resolved_at IS NULL;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

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
