import youid/uuid

/// Validated occurrence data with all IDs converted to UUIDs,
/// ready for database insertion
pub type Occurrence {
  Occurrence(
    applicant_id: uuid.Uuid,
    category_id: uuid.Uuid,
    subcategory_id: uuid.Uuid,
    description: String,
    location: List(Float),
    reference_point: String,
    vehicle_code: String,
    participants_id: List(uuid.Uuid),
  )
}
