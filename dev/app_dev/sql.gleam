//// This module contains the code to run the sql queries defined in
//// `./dev/app_dev/sql`.
//// > 🐿️ This module was generated automatically using v4.5.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog

/// Runs the `soft_truncate_user_account` query
/// defined in `./dev/app_dev/sql/soft_truncate_user_account.sql`.
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn soft_truncate_user_account(
  db: pog.Connection,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "DELETE FROM public.user_account
WHERE registration != '000';
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `truncate_brigade` query
/// defined in `./dev/app_dev/sql/truncate_brigade.sql`.
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn truncate_brigade(
  db: pog.Connection,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "TRUNCATE TABLE public.brigade CASCADE;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `truncate_occurrence` query
/// defined in `./dev/app_dev/sql/truncate_occurrence.sql`.
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn truncate_occurrence(
  db: pog.Connection,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "TRUNCATE TABLE public.occurrence CASCADE;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}
