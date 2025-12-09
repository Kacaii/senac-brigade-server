//// This module contains the code to run the sql queries defined in
//// `./src/app/domain/brigade/sql`.
//// > 🐿️ This module was generated automatically using v4.5.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `assign_brigade_members` query
/// defined in `./src/app/domain/brigade/sql/assign_brigade_members.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type AssignBrigadeMembersRow {
  AssignBrigadeMembersRow(inserted_user_id: Uuid)
}

///   Assign a list of members to a brigade
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn assign_brigade_members(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: List(Uuid),
) -> Result(pog.Returned(AssignBrigadeMembersRow), pog.QueryError) {
  let decoder = {
    use inserted_user_id <- decode.field(0, uuid_decoder())
    decode.success(AssignBrigadeMembersRow(inserted_user_id:))
  }

  "--   Assign a list of members to a brigade
select b.inserted_user_id
from public.assign_brigade_members($1, $2) as b;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(
    pog.array(fn(value) { pog.text(uuid.to_string(value)) }, arg_2),
  )
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_brigade_by_id` query
/// defined in `./src/app/domain/brigade/sql/delete_brigade_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteBrigadeByIdRow {
  DeleteBrigadeByIdRow(id: Uuid, brigade_name: String)
}

///   Remove a brigade from the DataBase
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_brigade_by_id(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(DeleteBrigadeByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use brigade_name <- decode.field(1, decode.string)
    decode.success(DeleteBrigadeByIdRow(id:, brigade_name:))
  }

  "--   Remove a brigade from the DataBase
delete from public.brigade as b
where b.id = $1
returning
    b.id,
    b.brigade_name;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `insert_new_brigade` query
/// defined in `./src/app/domain/brigade/sql/insert_new_brigade.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type InsertNewBrigadeRow {
  InsertNewBrigadeRow(id: Uuid, created_at: Timestamp)
}

///   Register a new brigade into the database
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_new_brigade(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: Bool,
) -> Result(pog.Returned(InsertNewBrigadeRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use created_at <- decode.field(1, pog.timestamp_decoder())
    decode.success(InsertNewBrigadeRow(id:, created_at:))
  }

  "--   Register a new brigade into the database
insert into public.brigade as b (
    leader_id,
    brigade_name,
    vehicle_code,
    is_active
) values (
    $1,
    $2,
    $3,
    $4
) returning
    b.id,
    b.created_at;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.bool(arg_4))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_all_brigades` query
/// defined in `./src/app/domain/brigade/sql/query_all_brigades.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryAllBrigadesRow {
  QueryAllBrigadesRow(
    id: Uuid,
    brigade_name: String,
    leader_name: Option(String),
    is_active: Bool,
  )
}

/// 󱉯  Find all registered brigades
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_all_brigades(
  db: pog.Connection,
) -> Result(pog.Returned(QueryAllBrigadesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use brigade_name <- decode.field(1, decode.string)
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
select
    b.id,
    b.brigade_name,
    u.full_name as leader_name,
    b.is_active
from public.brigade as b
left join public.user_account as u
    on b.leader_id = u.id;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_brigade_info` query
/// defined in `./src/app/domain/brigade/sql/query_brigade_info.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryBrigadeInfoRow {
  QueryBrigadeInfoRow(
    id: Uuid,
    brigade_name: String,
    leader_name: Uuid,
    is_active: Bool,
  )
}

/// 󰡦  Find details about a specific brigade
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_brigade_info(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryBrigadeInfoRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use brigade_name <- decode.field(1, decode.string)
    use leader_name <- decode.field(2, uuid_decoder())
    use is_active <- decode.field(3, decode.bool)
    decode.success(QueryBrigadeInfoRow(
      id:,
      brigade_name:,
      leader_name:,
      is_active:,
    ))
  }

  "-- 󰡦  Find details about a specific brigade
select
    b.id,
    b.brigade_name,
    u.id as leader_name,
    b.is_active
from public.brigade as b
inner join public.user_account as u
    on b.leader_id = u.id
where b.id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_members_id` query
/// defined in `./src/app/domain/brigade/sql/query_members_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryMembersIdRow {
  QueryMembersIdRow(id: Uuid)
}

///   Find the id of all members assigned a specific brigade
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_members_id(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryMembersIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(QueryMembersIdRow(id:))
  }

  "--   Find the id of all members assigned a specific brigade
select u.id
from public.user_account as u
inner join public.brigade_membership as bm
    on u.id = bm.user_id
where bm.brigade_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `query_members_info` query
/// defined in `./src/app/domain/brigade/sql/query_members_info.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryMembersInfoRow {
  QueryMembersInfoRow(id: Uuid, full_name: String, user_role: UserRoleEnum)
}

///   Find all members of a brigade
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_members_info(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(QueryMembersInfoRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use full_name <- decode.field(1, decode.string)
    use user_role <- decode.field(2, user_role_enum_decoder())
    decode.success(QueryMembersInfoRow(id:, full_name:, user_role:))
  }

  "--   Find all members of a brigade
select
    u.id,
    u.full_name,
    u.user_role
from public.user_account as u
inner join public.brigade_membership as bm
    on u.id = bm.user_id
where bm.brigade_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `replace_brigade_members` query
/// defined in `./src/app/domain/brigade/sql/replace_brigade_members.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ReplaceBrigadeMembersRow {
  ReplaceBrigadeMembersRow(inserted_user_id: Uuid)
}

///   Replace all brigade members
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn replace_brigade_members(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: List(Uuid),
) -> Result(pog.Returned(ReplaceBrigadeMembersRow), pog.QueryError) {
  let decoder = {
    use inserted_user_id <- decode.field(0, uuid_decoder())
    decode.success(ReplaceBrigadeMembersRow(inserted_user_id:))
  }

  "--   Replace all brigade members
select b.inserted_user_id
from public.replace_brigade_members($1, $2) as b;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(
    pog.array(fn(value) { pog.text(uuid.to_string(value)) }, arg_2),
  )
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_brigade_status` query
/// defined in `./src/app/domain/brigade/sql/update_brigade_status.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateBrigadeStatusRow {
  UpdateBrigadeStatusRow(id: Uuid, is_active: Bool, updated_at: Timestamp)
}

///   Set the brigade is_active status to ON or OFF
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
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
update public.brigade as b
set
    is_active = $2,
    updated_at = current_timestamp
where b.id = $1
returning
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
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
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
