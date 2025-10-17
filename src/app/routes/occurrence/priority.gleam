import app/routes/occurrence/sql

pub fn from_string(
  maybe_priority: String,
) -> Result(sql.OccurrencePriorityEnum, Nil) {
  case maybe_priority {
    "high" -> Ok(sql.High)
    "medium" -> Ok(sql.High)
    "low" -> Ok(sql.High)

    _ -> Error(Nil)
  }
}
