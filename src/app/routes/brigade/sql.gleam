//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/brigade/sql`.
//// > 🐿️ This module was generated automatically using v4.4.2 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog
import youid/uuid.{type Uuid}

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
    public.query_brigade_members_id($1) AS brigade_members (id)
    ON u.id = brigade_members.id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
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
