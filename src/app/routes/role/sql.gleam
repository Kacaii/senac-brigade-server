//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/role/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog

/// A row you get from running the `query_role_list` query
/// defined in `./src/app/routes/role/sql/query_role_list.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryRoleListRow {
  QueryRoleListRow(role_name: String)
}

///   Find all available roles
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_role_list(
  db: pog.Connection,
) -> Result(pog.Returned(QueryRoleListRow), pog.QueryError) {
  let decoder = {
    use role_name <- decode.field(0, decode.string)
    decode.success(QueryRoleListRow(role_name:))
  }

  "--   Find all available roles
SELECT r.role_name
FROM public.user_role AS r;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}
