//// This module contains the code to run the sql queries defined in
//// `./src/app/domain/dashboard/sql`.
//// > 🐿️ This module was generated automatically using v4.5.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog

/// A row you get from running the `query_dashboard_stats` query
/// defined in `./src/app/domain/dashboard/sql/query_dashboard_stats.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.5.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type QueryDashboardStatsRow {
  QueryDashboardStatsRow(
    active_brigades_count: Int,
    total_occurrences_count: Int,
    active_occurrences_count: Int,
    recent_occurrences_count: Int,
  )
}

/// 󱘟  Retrieve stats for the Dashboard page
///
/// > 🐿️ This function was generated automatically using v4.5.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn query_dashboard_stats(
  db: pog.Connection,
) -> Result(pog.Returned(QueryDashboardStatsRow), pog.QueryError) {
  let decoder = {
    use active_brigades_count <- decode.field(0, decode.int)
    use total_occurrences_count <- decode.field(1, decode.int)
    use active_occurrences_count <- decode.field(2, decode.int)
    use recent_occurrences_count <- decode.field(3, decode.int)
    decode.success(QueryDashboardStatsRow(
      active_brigades_count:,
      total_occurrences_count:,
      active_occurrences_count:,
      recent_occurrences_count:,
    ))
  }

  "-- 󱘟  Retrieve stats for the Dashboard page
select
    (select count from public.vw_count_active_brigades)
        as active_brigades_count,
    (select count from public.vw_count_total_occurrences)
        as total_occurrences_count,
    (select count from public.vw_count_active_occurrences)
        as active_occurrences_count,
    (select count from public.vw_count_recent_occurrences)
        as recent_occurrences_count;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}
