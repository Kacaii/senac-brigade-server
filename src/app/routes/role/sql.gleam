//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/role/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog

/// A row you get from running the `query_available_user_roles` query
/// defined in `./src/app/routes/role/sql/query_available_user_roles.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryAvailableUserRolesRow {
  QueryAvailableUserRolesRow(role_name: String)
}

///   Find all available user roles
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_available_user_roles(
  db: pog.Connection,
) -> Result(pog.Returned(QueryAvailableUserRolesRow), pog.QueryError) {
  let decoder = {
    use role_name <- decode.field(0, decode.string)
    decode.success(QueryAvailableUserRolesRow(role_name:))
  }

  "--   Find all available user roles
SELECT r.role_name
FROM public.user_role AS r;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}
