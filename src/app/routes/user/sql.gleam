//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/user/sql`.
//// > 🐿️ This module was generated automatically using v4.4.2 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `delete_user_by_id` query
/// defined in `./src/app/routes/user/sql/delete_user_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteUserByIdRow {
  DeleteUserByIdRow(id: Uuid, full_name: String)
}

///   Remove and user from the database
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_user_by_id(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(DeleteUserByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use full_name <- decode.field(1, decode.string)
    decode.success(DeleteUserByIdRow(id:, full_name:))
  }

  "--   Remove and user from the database
DELETE FROM public.user_account AS u
WHERE u.id = $1
RETURNING u.id, u.full_name;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `insert_new_user` query
/// defined in `./src/app/routes/user/sql/insert_new_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type InsertNewUserRow {
  InsertNewUserRow(id: Uuid)
}

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
  arg_6: UserRoleEnum,
) -> Result(pog.Returned(InsertNewUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(InsertNewUserRow(id:))
  }

  "--   Inserts a new user into the database
INSERT INTO public.user_account AS u
(
    full_name,
    registration,
    phone,
    email,
    password_hash,
    user_role
)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING u.id;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(user_role_enum_encoder(arg_6))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_all_users` query
/// defined in `./src/app/routes/user/sql/query_all_users.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryAllUsersRow {
  QueryAllUsersRow(
    id: Uuid,
    full_name: String,
    registration: String,
    email: Option(String),
    user_role: UserRoleEnum,
    is_active: Bool,
  )
}

/// 󰀖  Find all users on the database
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_all_users(
  db: pog.Connection,
) -> Result(pog.Returned(QueryAllUsersRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use full_name <- decode.field(1, decode.string)
    use registration <- decode.field(2, decode.string)
    use email <- decode.field(3, decode.optional(decode.string))
    use user_role <- decode.field(4, user_role_enum_decoder())
    use is_active <- decode.field(5, decode.bool)
    decode.success(QueryAllUsersRow(
      id:,
      full_name:,
      registration:,
      email:,
      user_role:,
      is_active:,
    ))
  }

  "-- 󰀖  Find all users on the database
SELECT
    u.id,
    u.full_name,
    u.registration,
    u.email,
    u.user_role,
    u.is_active
FROM public.user_account AS u;
"
  |> pog.query
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
    user_role: UserRoleEnum,
    brigade_id: Uuid,
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
    use user_role <- decode.field(2, user_role_enum_decoder())
    use brigade_id <- decode.field(3, uuid_decoder())
    decode.success(QueryCrewMembersRow(id:, full_name:, user_role:, brigade_id:))
  }

  "-- 󰢫  Retrieves detailed information about fellow brigade members
-- for a given user, including their names and role details.
SELECT
    u.id,
    u.full_name,
    u.user_role,
    crew.brigade_id
FROM public.query_crew_members($1) AS crew
INNER JOIN public.user_account AS u
    ON crew.member_id = u.id;
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
  QueryLoginTokenRow(id: Uuid, password_hash: String, user_role: UserRoleEnum)
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
    use user_role <- decode.field(2, user_role_enum_decoder())
    decode.success(QueryLoginTokenRow(id:, password_hash:, user_role:))
  }

  "--   Retrieves a user's ID and password hash from their registration
-- number for authentication purposes.
SELECT
    u.id,
    u.password_hash,
    u.user_role
FROM public.user_account AS u
WHERE u.registration = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_occurrences_by_participant` query
/// defined in `./src/app/routes/user/sql/query_occurrences_by_participant.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryOccurrencesByParticipantRow {
  QueryOccurrencesByParticipantRow(id: Uuid)
}

/// 󰡦  Find all occurrences a user participated in
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_occurrences_by_participant(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryOccurrencesByParticipantRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(QueryOccurrencesByParticipantRow(id:))
  }

  "-- 󰡦  Find all occurrences a user participated in
SELECT u.id
FROM public.user_account AS u
INNER JOIN public.brigade_membership AS bm
    ON u.id = bm.user_id
INNER JOIN public.occurrence_brigade AS ob
    ON bm.brigade_id = ob.brigade_id
WHERE ob.occurrence_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
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
    user_role: UserRoleEnum,
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
    use user_role <- decode.field(3, user_role_enum_decoder())
    use email <- decode.field(4, decode.optional(decode.string))
    use phone <- decode.field(5, decode.optional(decode.string))
    decode.success(QueryUserProfileRow(
      id:,
      full_name:,
      registration:,
      user_role:,
      email:,
      phone:,
    ))
  }

  "-- 󰀖  Find basic information about an user account
SELECT
    u.id,
    u.full_name,
    u.registration,
    u.user_role,
    u.email,
    u.phone
FROM public.user_account AS u
WHERE u.id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_user_role` query
/// defined in `./src/app/routes/user/sql/query_user_role.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryUserRoleRow {
  QueryUserRoleRow(user_role: UserRoleEnum)
}

/// 󰀖  Find user access level
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_user_role(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryUserRoleRow), pog.QueryError) {
  let decoder = {
    use user_role <- decode.field(0, user_role_enum_decoder())
    decode.success(QueryUserRoleRow(user_role:))
  }

  "-- 󰀖  Find user access level
SELECT u.user_role
FROM
    public.user_account AS u
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
pub fn update_user_password(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "--   Set an new value to the password of an user
UPDATE public.user_account
SET
    password_hash = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_user_status` query
/// defined in `./src/app/routes/user/sql/update_user_status.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateUserStatusRow {
  UpdateUserStatusRow(id: Uuid, is_active: Bool)
}

/// 󰚰  Update an user `is_active` field
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_user_status(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Bool,
) -> Result(pog.Returned(UpdateUserStatusRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use is_active <- decode.field(1, decode.bool)
    decode.success(UpdateUserStatusRow(id:, is_active:))
  }

  "-- 󰚰  Update an user `is_active` field
UPDATE public.user_account AS u
SET
    is_active = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE u.id = $1
RETURNING u.id, u.is_active;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.bool(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `user_role_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
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

fn user_role_enum_encoder(user_role_enum) -> pog.Value {
  case user_role_enum {
    Sargeant -> "sargeant"
    Developer -> "developer"
    Captain -> "captain"
    Firefighter -> "firefighter"
    Analyst -> "analyst"
    Admin -> "admin"
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
