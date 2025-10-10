import gleam/string
import glight
import wisp
import youid/uuid

pub fn from_string_pt_br(role_name role_name: String) -> Result(Role, String) {
  case string.lowercase(role_name) {
    "administrador" -> Ok(Admin)
    "analista" -> Ok(Analist)
    "bombeiro" -> Ok(Firefighter)
    "capitão" -> Ok(Captain)
    "desenvolvedor" -> Ok(Developer)
    "sargento" -> Ok(Sargeant)

    unknown -> Error(unknown)
  }
}

pub fn to_string_pt_br(user_role user_role: Role) -> String {
  case user_role {
    Admin -> "administrador"
    Analist -> "analista"
    Captain -> "capitão"
    Developer -> "desenvolvedor"
    Firefighter -> "bombeiro"
    Sargeant -> "sargento"
  }
}

pub fn from_string(role_name role_name: String) -> Result(Role, String) {
  case string.lowercase(role_name) {
    "admin" -> Ok(Admin)
    "analist" -> Ok(Analist)
    "firefighter" -> Ok(Firefighter)
    "captain" -> Ok(Captain)
    "developer" -> Ok(Developer)
    "sargeant" -> Ok(Sargeant)

    unknown -> Error(unknown)
  }
}

pub fn to_string(user_role user_role: Role) -> String {
  case user_role {
    Admin -> "admin"
    Analist -> "analist"
    Captain -> "captain"
    Developer -> "developer"
    Firefighter -> "firefighter"
    Sargeant -> "sargeant"
  }
}

pub type Role {
  Sargeant
  Developer
  Captain
  Firefighter
  Analist
  Admin
}

/// 󰞏  Log when someone tries to access an endpoint that they dont have permission
pub fn log_unauthorized_access_attempt(
  request request: wisp.Request,
  user_uuid user_uuid: uuid.Uuid,
  user_role user_role: Role,
) -> Nil {
  glight.logger()
  |> glight.with("path", request.path)
  |> glight.with("user", uuid.to_string(user_uuid))
  |> glight.with("role", to_string(user_role))
  |> glight.notice("unauthorized_access_attempt")

  Nil
}
