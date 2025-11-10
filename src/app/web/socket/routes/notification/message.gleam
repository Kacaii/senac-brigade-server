import app/routes/occurrence/category
import youid/uuid

pub type Msg {
  NewOccurrence(occ_id: uuid.Uuid, occ_type: category.Category)
}
