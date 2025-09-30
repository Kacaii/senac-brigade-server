//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/user/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `get_crew_members` query
/// defined in `./src/app/routes/user/sql/get_crew_members.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetCrewMembersRow {
  GetCrewMembersRow(
    id: Uuid,
    full_name: String,
    role_name: Option(String),
    description: Option(String),
  )
}

/// 󰢫  Retrieves detailed information about fellow brigade members
/// for a given user, including their names and role details.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_crew_members(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetCrewMembersRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use full_name <- decode.field(1, decode.string)
    use role_name <- decode.field(2, decode.optional(decode.string))
    use description <- decode.field(3, decode.optional(decode.string))
    decode.success(GetCrewMembersRow(id:, full_name:, role_name:, description:))
  }

  "-- 󰢫  Retrieves detailed information about fellow brigade members
-- for a given user, including their names and role details.
SELECT
    u.id,
    u.full_name,
    r.role_name,
    r.description
FROM QUERY_FELLOW_BRIGADE_MEMBERS_ID($1) AS crew_members (id)
INNER JOIN
    public.user_account AS u
    ON crew_members.id = u.id
LEFT JOIN
    public.user_role AS r
    ON u.role_id = r.id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_login_token` query
/// defined in `./src/app/routes/user/sql/get_login_token.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetLoginTokenRow {
  GetLoginTokenRow(id: Uuid, password_hash: String)
}

///   Retrieves a user's ID and password hash from their registration
/// number for authentication purposes.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_login_token(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(GetLoginTokenRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use password_hash <- decode.field(1, decode.string)
    decode.success(GetLoginTokenRow(id:, password_hash:))
  }

  "--   Retrieves a user's ID and password hash from their registration
-- number for authentication purposes.
SELECT
    u.id,
    u.password_hash
FROM public.user_account AS u
WHERE u.registration = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_user_id_by_registration` query
/// defined in `./src/app/routes/user/sql/get_user_id_by_registration.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUserIdByRegistrationRow {
  GetUserIdByRegistrationRow(id: Uuid)
}

///   Retrieves a user's ID from their registration number.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_user_id_by_registration(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(GetUserIdByRegistrationRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(GetUserIdByRegistrationRow(id:))
  }

  "--   Retrieves a user's ID from their registration number.
SELECT u.id
FROM public.user_account AS u
WHERE u.registration = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_user_name` query
/// defined in `./src/app/routes/user/sql/get_user_name.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUserNameRow {
  GetUserNameRow(full_name: String)
}

///   Retrieves a user's full name by their user ID.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_user_name(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(GetUserNameRow), pog.QueryError) {
  let decoder = {
    use full_name <- decode.field(0, decode.string)
    decode.success(GetUserNameRow(full_name:))
  }

  "--   Retrieves a user's full name by their user ID.
SELECT u.full_name
FROM public.user_account AS u
WHERE u.id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

///   Inserts a new user into the database
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_new_user(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "--   Inserts a new user into the database
INSERT INTO public.user_account (
    full_name,
    registration,
    phone,
    email,
    password_hash
) VALUES (
    $1, $2, $3, $4, $5
)
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
