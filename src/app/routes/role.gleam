import gleam/string

pub fn from_string(role_name role_name: String) -> Role {
  case string.lowercase(role_name) {
    "administrador" -> Admin
    "analista" -> Analist
    "bombeiro" -> Firefighter
    "capitão" -> Captain
    "desenvolvedor" -> Developer
    "sargento" -> Sargeant
    _ -> None
  }
}

pub fn to_string(role role: Role) -> String {
  let role_string = case role {
    Admin -> "administrador"
    Analist -> "analista"
    Firefighter -> "bombeiro"
    Captain -> "capitão"
    Developer -> "desenvolvedor"
    Sargeant -> "sargento"
    _ -> ""
  }

  string.capitalise(role_string)
}

pub type Role {
  Admin
  Analist
  Captain
  Developer
  Firefighter
  Sargeant

  None
}
