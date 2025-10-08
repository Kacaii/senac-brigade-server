//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/user/sql`.
//// > 🐿️ This module was generated automatically using v4.4.2 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import pog
import youid/uuid.{type Uuid}

///   Inserts a new user into the database
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
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

/// A row you get from running the `query_crew_members` query
/// defined in `./src/app/routes/user/sql/query_crew_members.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryCrewMembersRow {
  QueryCrewMembersRow(
    id: Uuid,
    full_name: String,
    role_name: Option(String),
    description: Option(String),
  )
}

/// 󰢫  Retrieves detailed information about fellow brigade members
/// for a given user, including their names and role details.
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_crew_members(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryCrewMembersRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use full_name <- decode.field(1, decode.string)
    use role_name <- decode.field(2, decode.optional(decode.string))
    use description <- decode.field(3, decode.optional(decode.string))
    decode.success(QueryCrewMembersRow(
      id:,
      full_name:,
      role_name:,
      description:,
    ))
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

/// A row you get from running the `query_login_token` query
/// defined in `./src/app/routes/user/sql/query_login_token.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryLoginTokenRow {
  QueryLoginTokenRow(id: Uuid, password_hash: String)
}

///   Retrieves a user's ID and password hash from their registration
/// number for authentication purposes.
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_login_token(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(QueryLoginTokenRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use password_hash <- decode.field(1, decode.string)
    decode.success(QueryLoginTokenRow(id:, password_hash:))
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

/// A row you get from running the `query_user_id_by_registration` query
/// defined in `./src/app/routes/user/sql/query_user_id_by_registration.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryUserIdByRegistrationRow {
  QueryUserIdByRegistrationRow(id: Uuid)
}

///   Retrieves a user's ID from their registration number.
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_user_id_by_registration(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(QueryUserIdByRegistrationRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(QueryUserIdByRegistrationRow(id:))
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

/// A row you get from running the `query_user_name` query
/// defined in `./src/app/routes/user/sql/query_user_name.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryUserNameRow {
  QueryUserNameRow(full_name: String)
}

///   Retrieves a user's full name by their user ID.
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_user_name(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryUserNameRow), pog.QueryError) {
  let decoder = {
    use full_name <- decode.field(0, decode.string)
    decode.success(QueryUserNameRow(full_name:))
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

/// A row you get from running the `query_user_password` query
/// defined in `./src/app/routes/user/sql/query_user_password.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryUserPasswordRow {
  QueryUserPasswordRow(password_hash: String)
}

///   Find the password hash from an user
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_user_password(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryUserPasswordRow), pog.QueryError) {
  let decoder = {
    use password_hash <- decode.field(0, decode.string)
    decode.success(QueryUserPasswordRow(password_hash:))
  }

  "--   Find the password hash from an user
SELECT u.password_hash
FROM public.user_account AS u
WHERE u.id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_user_profile` query
/// defined in `./src/app/routes/user/sql/query_user_profile.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryUserProfileRow {
  QueryUserProfileRow(
    id: Uuid,
    full_name: String,
    registration: String,
    role_name: Option(String),
    email: Option(String),
    phone: Option(String),
  )
}

/// 󰀖  Find basic information about an user account
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_user_profile(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryUserProfileRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use full_name <- decode.field(1, decode.string)
    use registration <- decode.field(2, decode.string)
    use role_name <- decode.field(3, decode.optional(decode.string))
    use email <- decode.field(4, decode.optional(decode.string))
    use phone <- decode.field(5, decode.optional(decode.string))
    decode.success(QueryUserProfileRow(
      id:,
      full_name:,
      registration:,
      role_name:,
      email:,
      phone:,
    ))
  }

  "-- 󰀖  Find basic information about an user account
SELECT
    u.id,
    u.full_name,
    u.registration,
    r.role_name,
    u.email,
    u.phone
FROM
    public.user_account AS u
LEFT JOIN public.user_role AS r
    ON u.role_id = r.id
WHERE u.id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_user_role_name` query
/// defined in `./src/app/routes/user/sql/query_user_role_name.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryUserRoleNameRow {
  QueryUserRoleNameRow(role_name: String)
}

/// 󰀖  Find user access level
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_user_role_name(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryUserRoleNameRow), pog.QueryError) {
  let decoder = {
    use role_name <- decode.field(0, decode.string)
    decode.success(QueryUserRoleNameRow(role_name:))
  }

  "-- 󰀖  Find user access level
SELECT ur.role_name FROM
    public.user_account AS u
INNER JOIN public.user_role AS ur
    ON u.role_id = ur.id
WHERE u.id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

///   Set an new value to the password of an user
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_password(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "--   Set an new value to the password of an user
UPDATE public.user_account
SET password_hash = $2
WHERE id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
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
