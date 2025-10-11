//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/admin/sql`.
//// > 🐿️ This module was generated automatically using v4.4.2 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog

/// A row you get from running the `count_total_users` query
/// defined in `./src/app/routes/admin/sql/count_total_users.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.2 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CountTotalUsersRow {
  CountTotalUsersRow(total: Int)
}

/// 󰆙  Count the total number of users in our system
///
/// > 🐿️ This function was generated automatically using v4.4.2 of
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
SELECT COUNT(u.id) AS total
FROM public.user_account AS u;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}
