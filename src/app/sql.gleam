//// This module contains the code to run the sql queries defined in
//// `./src/app/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `count_active_brigades` query
/// defined in `./src/app/sql/count_active_brigades.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CountActiveBrigadesRow {
  CountActiveBrigadesRow(count: Int)
}

/// Runs the `count_active_brigades` query
/// defined in `./src/app/sql/count_active_brigades.sql`.
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

  "SELECT COUNT(id)
FROM brigade
WHERE is_active = TRUE;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_brigade_members` query
/// defined in `./src/app/sql/get_brigade_members.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetBrigadeMembersRow {
  GetBrigadeMembersRow(full_name: String, registration: String)
}

/// Runs the `get_brigade_members` query
/// defined in `./src/app/sql/get_brigade_members.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_brigade_members(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetBrigadeMembersRow), pog.QueryError) {
  let decoder = {
    use full_name <- decode.field(0, decode.string)
    use registration <- decode.field(1, decode.string)
    decode.success(GetBrigadeMembersRow(full_name:, registration:))
  }

  "SELECT
    u.full_name,
    u.registration
FROM user_account AS u
INNER JOIN brigade_membership AS bm ON u.id = bm.user_id
WHERE bm.brigade_id = $1 -- <- Brigade ID here
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `register_new_user` query
/// defined in `./src/app/sql/register_new_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn register_new_user(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "INSERT INTO user_account (
    full_name, registration, phone, email, password_hash
) VALUES ($1, $2, $3, $4, $5)
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}
