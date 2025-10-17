import app/routes/occurrence/category
import app/routes/occurrence/subcategory
import gleam/option
import youid/uuid

pub type Occurrence {
  Occurrence(
    occurrence_category: category.Category,
    occurrence_subcategory: option.Option(subcategory.Subcategory),
    brigade_id: option.Option(uuid.Uuid),
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
  )
}
