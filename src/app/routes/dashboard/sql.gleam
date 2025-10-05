//// This module contains the code to run the sql queries defined in
//// `./src/app/routes/dashboard/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog

/// A row you get from running the `query_dashboard_stats` query
/// defined in `./src/app/routes/dashboard/sql/query_dashboard_stats.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
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

/// Runs the `query_dashboard_stats` query
/// defined in `./src/app/routes/dashboard/sql/query_dashboard_stats.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
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

  "SELECT
    (
        SELECT count
        FROM public.vw_count_active_brigades
    ) AS active_brigades_count,
    (
        SELECT count
        FROM public.vw_count_total_occurrences
    ) AS total_occurrences_count,
    (
        SELECT count
        FROM public.vw_count_active_occurrences
    ) AS active_occurrences_count,
    (
        SELECT count FROM
            public.vw_count_recent_occurrences
    ) AS recent_occurrences_count;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}
