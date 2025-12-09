//// This module contains the code to run the sql queries defined in
//// `./src/app/domain/admin/sql`.
//// > 🐿️ This module was generated automatically using v4.5.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `admin_update_user` query
/// defined in `./src/app/domain/admin/sql/admin_update_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type AdminUpdateUserRow {
  AdminUpdateUserRow(
    id: Uuid,
    full_name: String,
    email: String,
    user_role: UserRoleEnum,
    registration: String,
    is_active: Bool,
    updated_at: Timestamp,
  )
}

///   Update an user's information as admin
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn admin_update_user(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: String,
  arg_4: UserRoleEnum,
  arg_5: String,
  arg_6: Bool,
) -> Result(pog.Returned(AdminUpdateUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use full_name <- decode.field(1, decode.string)
    use email <- decode.field(2, decode.string)
    use user_role <- decode.field(3, user_role_enum_decoder())
    use registration <- decode.field(4, decode.string)
    use is_active <- decode.field(5, decode.bool)
    use updated_at <- decode.field(6, pog.timestamp_decoder())
    decode.success(AdminUpdateUserRow(
      id:,
      full_name:,
      email:,
      user_role:,
      registration:,
      is_active:,
      updated_at:,
    ))
  }

  "--   Update an user's information as admin
update public.user_account as u
set
    full_name = $2,
    email = $3,
    user_role = $4,
    registration = $5,
    is_active = $6,
    updated_at = current_timestamp
where u.id = $1
returning
    u.id,
    u.full_name,
    u.email,
    u.user_role,
    u.registration,
    u.is_active,
    u.updated_at;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(user_role_enum_encoder(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.bool(arg_6))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `count_total_users` query
/// defined in `./src/app/domain/admin/sql/count_total_users.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CountTotalUsersRow {
  CountTotalUsersRow(total: Int)
}

/// 󰆙  Count the total number of users in our system
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn count_total_users(
  db: pog.Connection,
) -> Result(pog.Returned(CountTotalUsersRow), pog.QueryError) {
  let decoder = {
    use total <- decode.field(0, decode.int)
    decode.success(CountTotalUsersRow(total:))
  }

  "-- 󰆙  Count the total number of users in our system
select count(u.id) as total
from public.user_account as u;
"
  |> pog.query
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
