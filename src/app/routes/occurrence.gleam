import app/routes/occurrence/sql
import youid/uuid

pub type Occurrence {
  Occurrence(
    occurrence_category: sql.OccurrenceCategoryEnum,
    occurrence_subcategory: sql.OccurrenceSubcategoryEnum,
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
    participants_id: List(uuid.Uuid),
  )
}
