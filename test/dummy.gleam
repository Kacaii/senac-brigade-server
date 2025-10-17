//// For testing purposes only

import app/routes/brigade/sql as b_sql
import app/routes/occurrence/category
import app/routes/occurrence/priority
import app/routes/occurrence/subcategory
import app/routes/role
import app/routes/user/sql as u_sql
import app/web
import gleam/dict
import gleam/int
import gleam/list
import wisp
import youid/uuid

/// Panics on failure
pub fn random_role() -> role.Role {
  let samples =
    dict.from_list([
      #(0, role.Firefighter),
      #(1, role.Admin),
      #(2, role.Analist),
      #(3, role.Captain),
      #(4, role.Developer),
      #(5, role.Sargeant),
    ])

  let assert Ok(chosen) =
    dict.get(samples, {
      dict.to_list(samples)
      |> list.length()
      |> int.random()
    })
    as "Failed to pick a random user role"

  chosen
}

/// Panics on failure
pub fn random_priority() {
  let samples =
    dict.from_list([
      #(0, priority.Low),
      #(1, priority.Medium),
      #(2, priority.High),
    ])

  let assert Ok(chosen) =
    dict.get(samples, {
      dict.to_list(samples)
      |> list.length()
      |> int.random()
    })
    as "Failed to pick a random occurrence priority"

  chosen
}

/// Panics on failure
pub fn random_brigade(
  ctx ctx: web.Context,
  applicant applicant: uuid.Uuid,
  participants participants: List(uuid.Uuid),
) {
  let assert Ok(returned) =
    b_sql.insert_new_brigade(ctx.conn, applicant, "wobble", participants, True)
    as "Failed to create dummy brigade"

  let assert Ok(row) = list.first(returned.rows)
    as "Database returned no results"

  row.id
}

/// Panics on failure
pub fn random_category() {
  let samples =
    dict.from_list([
      #(0, category.Other),
      #(1, category.Fire),
      #(2, category.MedicEmergency),
      #(3, category.TrafficAccident),
    ])

  let assert Ok(chosen) =
    dict.get(samples, {
      dict.to_list(samples)
      |> list.length()
      |> int.random()
    })
    as "Failed to pick a random user occurrence category"

  chosen
}

/// Panics on failure
pub fn random_subcategory() {
  let samples =
    dict.from_list([
      #(0, subcategory.InjuredAnimal),
      #(1, subcategory.Flood),
      #(2, subcategory.TreeCrash),
      #(3, subcategory.MotorcycleCrash),
      #(4, subcategory.Rollover),
      #(5, subcategory.RunOver),
      #(6, subcategory.Collision),
      #(7, subcategory.Vehicle),
      #(8, subcategory.Vegetation),
      #(9, subcategory.Comercial),
      #(10, subcategory.Residential),
      #(11, subcategory.Intoxication),
      #(12, subcategory.SeriousInjury),
      #(13, subcategory.Seizure),
      #(14, subcategory.PreHospitalCare),
      #(15, subcategory.HeartStop),
    ])

  let assert Ok(chosen) =
    dict.get(samples, {
      dict.to_list(samples)
      |> list.length()
      |> int.random()
    })
    as "Failed to pick a random occurrence subcategory"

  chosen
}

/// Panics on failure
pub fn random_user(ctx: web.Context) -> uuid.Uuid {
  let r_role = random_role()
  let role_to_enum = fn(role: role.Role) {
    case role {
      role.Admin -> u_sql.Admin
      role.Analist -> u_sql.Analist
      role.Captain -> u_sql.Captain
      role.Developer -> u_sql.Developer
      role.Firefighter -> u_sql.Firefighter
      role.Sargeant -> u_sql.Sargeant
    }
  }

  let assert Ok(returned) =
    u_sql.insert_new_user(
      ctx.conn,
      wisp.random_string(6),
      wisp.random_string(6),
      int.random(3_333_333_333) |> int.to_string(),
      wisp.random_string(6) <> "@email.com",
      "",
      role_to_enum(r_role),
    )
    as "Failed to create dummy user"

  let assert Ok(row) = list.first(returned.rows)
  row.id
}
