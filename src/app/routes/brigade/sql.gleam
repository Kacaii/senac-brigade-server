//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/brigade/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `count_active_brigades` query
/// defined in `./src/app/routes/brigade/sql/count_active_brigades.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CountActiveBrigadesRow {
  CountActiveBrigadesRow(count: Int)
}

/// 󰆙  Counts the number of active brigades in the database.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn count_active_brigades(
  db: pog.Connection,
) -> Result(pog.Returned(CountActiveBrigadesRow), pog.QueryError) {
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(CountActiveBrigadesRow(count:))
  }

  "-- 󰆙  Counts the number of active brigades in the database.
SELECT COUNT(id)
FROM public.brigade
WHERE is_active = TRUE;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_brigade_members` query
/// defined in `./src/app/routes/brigade/sql/get_brigade_members.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBrigadeMembersRow {
  GetBrigadeMembersRow(
    id: Uuid,
    full_name: String,
    role_name: Option(String),
    description: Option(String),
  )
}

///   Find all members of a brigade
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_brigade_members(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetBrigadeMembersRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use full_name <- decode.field(1, decode.string)
    use role_name <- decode.field(2, decode.optional(decode.string))
    use description <- decode.field(3, decode.optional(decode.string))
    decode.success(GetBrigadeMembersRow(
      id:,
      full_name:,
      role_name:,
      description:,
    ))
  }

  "--   Find all members of a brigade
SELECT
    u.id,
    u.full_name,
    r.role_name,
    r.description
FROM public.user_account AS u
LEFT JOIN
    public.user_role AS r
    ON u.role_id = r.id
INNER JOIN
    public.query_brigade_members_id($1) AS brigade_members (id)
    ON u.id = brigade_members.id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
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
