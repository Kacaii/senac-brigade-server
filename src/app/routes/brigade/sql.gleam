//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/brigade/sql`.
//// > 🐿️ This module was generated automatically using v4.4.2 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `delete_brigade_by_id` query
/// defined in `./src/app/routes/brigade/sql/delete_brigade_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteBrigadeByIdRow {
  DeleteBrigadeByIdRow(id: Uuid, brigade_name: Option(String))
}

///   Remove a brigade from the DataBase
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_brigade_by_id(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(DeleteBrigadeByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use brigade_name <- decode.field(1, decode.optional(decode.string))
    decode.success(DeleteBrigadeByIdRow(id:, brigade_name:))
  }

  "--   Remove a brigade from the DataBase
DELETE FROM public.brigade AS b
WHERE b.id = $1
RETURNING
    b.id,
    b.brigade_name;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `insert_new_brigade` query
/// defined in `./src/app/routes/brigade/sql/insert_new_brigade.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type InsertNewBrigadeRow {
  InsertNewBrigadeRow(id: Uuid, created_at: Timestamp)
}

///   Registe a new brigade into the database
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_new_brigade(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: List(Uuid),
  arg_5: Bool,
) -> Result(pog.Returned(InsertNewBrigadeRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use created_at <- decode.field(1, pog.timestamp_decoder())
    decode.success(InsertNewBrigadeRow(id:, created_at:))
  }

  "--   Registe a new brigade into the database
INSERT INTO public.brigade AS b (
    leader_id,
    brigade_name,
    vehicle_code,
    members_id,
    is_active
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5
) RETURNING
    b.id,
    b.created_at;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(
    pog.array(fn(value) { pog.text(uuid.to_string(value)) }, arg_4),
  )
  |> pog.parameter(pog.bool(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_all_brigades` query
/// defined in `./src/app/routes/brigade/sql/query_all_brigades.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryAllBrigadesRow {
  QueryAllBrigadesRow(
    id: Uuid,
    brigade_name: Option(String),
    leader_name: Option(String),
    is_active: Bool,
  )
}

/// 󱉯  Find all registered brigades
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_all_brigades(
  db: pog.Connection,
) -> Result(pog.Returned(QueryAllBrigadesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use brigade_name <- decode.field(1, decode.optional(decode.string))
    use leader_name <- decode.field(2, decode.optional(decode.string))
    use is_active <- decode.field(3, decode.bool)
    decode.success(QueryAllBrigadesRow(
      id:,
      brigade_name:,
      leader_name:,
      is_active:,
    ))
  }

  "-- 󱉯  Find all registered brigades
SELECT
    b.id,
    b.brigade_name,
    u.full_name AS leader_name,
    b.is_active
FROM public.brigade AS b
LEFT JOIN public.user_account AS u
    ON b.leader_id = u.id;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_brigade_by_id` query
/// defined in `./src/app/routes/brigade/sql/query_brigade_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryBrigadeByIdRow {
  QueryBrigadeByIdRow(
    id: Uuid,
    brigade_name: Option(String),
    leader_name: Uuid,
    is_active: Bool,
  )
}

/// 󰡦  Find details about a specific brigade
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_brigade_by_id(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryBrigadeByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use brigade_name <- decode.field(1, decode.optional(decode.string))
    use leader_name <- decode.field(2, uuid_decoder())
    use is_active <- decode.field(3, decode.bool)
    decode.success(QueryBrigadeByIdRow(
      id:,
      brigade_name:,
      leader_name:,
      is_active:,
    ))
  }

  "-- 󰡦  Find details about a specific brigade
SELECT
    b.id,
    b.brigade_name,
    u.id AS leader_name,
    b.is_active
FROM public.brigade AS b
INNER JOIN public.user_account AS u
    ON b.leader_id = u.id
WHERE b.id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_brigade_members` query
/// defined in `./src/app/routes/brigade/sql/query_brigade_members.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryBrigadeMembersRow {
  QueryBrigadeMembersRow(id: Uuid, full_name: String, user_role: UserRoleEnum)
}

///   Find all members of a brigade
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_brigade_members(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryBrigadeMembersRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use full_name <- decode.field(1, decode.string)
    use user_role <- decode.field(2, user_role_enum_decoder())
    decode.success(QueryBrigadeMembersRow(id:, full_name:, user_role:))
  }

  "--   Find all members of a brigade
SELECT
    u.id,
    u.full_name,
    u.user_role
FROM public.user_account AS u
INNER JOIN
    public.brigade AS b
    ON u.id = ANY(b.members_id)
WHERE b.id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_brigade_status` query
/// defined in `./src/app/routes/brigade/sql/update_brigade_status.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateBrigadeStatusRow {
  UpdateBrigadeStatusRow(id: Uuid, is_active: Bool, updated_at: Timestamp)
}

///   Set the brigade is_active status to ON or OFF
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_brigade_status(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Bool,
) -> Result(pog.Returned(UpdateBrigadeStatusRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use is_active <- decode.field(1, decode.bool)
    use updated_at <- decode.field(2, pog.timestamp_decoder())
    decode.success(UpdateBrigadeStatusRow(id:, is_active:, updated_at:))
  }

  "--   Set the brigade is_active status to ON or OFF
UPDATE public.brigade AS b
SET
    is_active = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE b.id = $1
RETURNING
    b.id,
    b.is_active,
    b.updated_at;
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
  Analist
  Admin
}

fn user_role_enum_decoder() -> decode.Decoder(UserRoleEnum) {
  use user_role_enum <- decode.then(decode.string)
  case user_role_enum {
    "sargeant" -> decode.success(Sargeant)
    "developer" -> decode.success(Developer)
    "captain" -> decode.success(Captain)
    "firefighter" -> decode.success(Firefighter)
    "analist" -> decode.success(Analist)
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
