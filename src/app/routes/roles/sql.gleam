//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/roles/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/json
import gleam/dynamic/decode
import pog

/// A row you get from running the `roles` query
/// defined in `./src/app/routes/roles/sql/roles.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type RolesRow {
  RolesRow(role_name: String)
}

fn roles_row_to_json(roles_row: RolesRow) -> json.Json {
  let RolesRow(role_name:) = roles_row
  json.object([
    #("role_name", json.string(role_name)),
  ])
}

/// Runs the `roles` query
/// defined in `./src/app/routes/roles/sql/roles.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn roles(
  db: pog.Connection,
) -> Result(pog.Returned(RolesRow), pog.QueryError) {
  let decoder = {
    use role_name <- decode.field(0, decode.string)
    decode.success(RolesRow(role_name:))
  }

  "select role_name from public.user_role;"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}
