//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/role/sql`.
//// > 🐿️ This module was generated automatically using v4.4.2 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog

/// A row you get from running the `query_available_user_roles` query
/// defined in `./src/app/routes/role/sql/query_available_user_roles.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryAvailableUserRolesRow {
  QueryAvailableUserRolesRow(available_role: UserRoleEnum)
}

///   Find all available user roles
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_available_user_roles(
  db: pog.Connection,
) -> Result(pog.Returned(QueryAvailableUserRolesRow), pog.QueryError) {
  let decoder = {
    use available_role <- decode.field(0, user_role_enum_decoder())
    decode.success(QueryAvailableUserRolesRow(available_role:))
  }

  "--   Find all available user roles
SELECT UNNEST(ENUM_RANGE(NULL::public.USER_ROLE_ENUM)) AS available_role;
"
  |> pog.query
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
