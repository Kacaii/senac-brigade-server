import app/routes/occurrence.{type Occurrence}
import app/routes/occurrence/count_active_occurrences
import app/web.{type Context}
import gleam/result
import wisp

// TODO: Docs
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  let query_result = {
    use active_occurrences <- result.try({
      count_active_occurrences.handle_query(ctx:)
    })
    todo
  }

  todo
}

// TODO: Docs
pub type DashBoard {
  DashBoard(active_occurrences: Int, recent_occurrence: List(Occurrence))
}
