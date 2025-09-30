import app/routes/occurrence/sql
import app/web.{type Context}
import gleam/list
import gleam/result

// TODO: Documentation
pub fn handle_query(
  ctx ctx: Context,
) -> Result(Int, CountActiveOccurrencesError) {
  let query_result = {
    use returned <- result.try(
      sql.count_active_occurrences(ctx.conn)
      |> result.replace_error(DataBaseError),
    )
    use row <- result.try(
      list.first(returned.rows)
      |> result.replace_error(DataBaseReturnedEmptyRow),
    )

    Ok(row.count)
  }

  case query_result {
    Error(err) -> Error(err)
    Ok(count) -> Ok(count)
  }
}

pub opaque type CountActiveOccurrencesError {
  DataBaseReturnedEmptyRow
  DataBaseError
}
