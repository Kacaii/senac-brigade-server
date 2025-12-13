//// For testing purposes only

import app/domain/brigade/sql as b_sql
import app/domain/occurrence/category
import app/domain/occurrence/priority
import app/domain/occurrence/sql as o_sql
import app/domain/occurrence/subcategory
import app/domain/role
import app/domain/user/sql as u_sql
import app/web/context
import gleam/float
import gleam/list
import gleam/set
import pog
import wisp
import youid/uuid

/// Panics on failure
pub fn random_role() -> role.Role {
  let samples = [
    role.Firefighter,
    role.Admin,
    role.Analyst,
    role.Captain,
    role.Developer,
    role.Sargeant,
  ]

  let assert Ok(chosen) = list.first(list.sample(samples, 1))
    as "Picked a random user role"

  chosen
}

/// Panics on failure
pub fn random_priority() -> priority.Priority {
  let samples = [
    priority.Low,
    priority.Medium,
    priority.High,
  ]

  let assert Ok(chosen) = list.first(list.sample(samples, 1))
    as "Picked a random occurrence priority"

  chosen
}

/// Panics on failure
pub fn random_brigade(
  conn conn: pog.Connection,
  leader_id leader_id: uuid.Uuid,
  members dummy_members: List(uuid.Uuid),
) -> uuid.Uuid {
  let assert Ok(returned) =
    b_sql.insert_new_brigade(
      conn,
      leader_id,
      "BRIGADE " <> wisp.random_string(4),
      "VEHICLE " <> wisp.random_string(3),
      True,
    )
    as "Dummy brigade is generated"

  let assert Ok(inserted_brigade_row) = list.first(returned.rows)
    as "Database returned results after creating new Brigade"

  let assert Ok(assigments) =
    b_sql.assign_brigade_members(conn, inserted_brigade_row.id, dummy_members)
    as "Dummy members were assigned"

  let assigned_members =
    list.map(assigments.rows, fn(row) { row.inserted_user_id })

  let assigned_members_set = set.from_list(assigned_members)
  let dummy_members_set = set.from_list(dummy_members)

  assert set.difference(assigned_members_set, dummy_members_set)
    |> set.to_list
    == []
    as "Returned members expected users"

  assert set.difference(dummy_members_set, assigned_members_set)
    |> set.to_list
    == []
    as "All brigade members were returned"

  inserted_brigade_row.id
}

/// Panic on failure
pub fn clean_brigade(conn: pog.Connection, dummy: uuid.Uuid) -> Nil {
  let cleanup_brigade_id = {
    let assert Ok(returned) = b_sql.delete_brigade_by_id(conn, dummy)
      as "Failed to delete dummy brigade"

    let assert Ok(row) = list.first(returned.rows)
      as "Not results after deleting a brigade"

    row.id
  }

  assert cleanup_brigade_id == dummy as "Deleted the wrong Brigade"
}

/// Panics on failure
pub fn random_category() -> category.Category {
  let samples = [
    category.Other,
    category.Fire,
    category.MedicEmergency,
    category.TrafficAccident,
  ]

  let assert Ok(chosen) = list.first(list.sample(samples, 1))
    as "Failed to pick a random user occurrence category"

  chosen
}

/// Panics on failure
pub fn random_subcategory() -> subcategory.Subcategory {
  let samples = [
    subcategory.InjuredAnimal,
    subcategory.Flood,
    subcategory.TreeCrash,
    subcategory.MotorcycleCrash,
    subcategory.Rollover,
    subcategory.RunOver,
    subcategory.Collision,
    subcategory.Vehicle,
    subcategory.Vegetation,
    subcategory.Comercial,
    subcategory.Residential,
    subcategory.Intoxication,
    subcategory.SeriousInjury,
    subcategory.Seizure,
    subcategory.PreHospitalCare,
    subcategory.HeartStop,
  ]

  let assert Ok(chosen) = list.first(list.sample(samples, 1))
    as "Failed to pick a random occurrence subcategory"

  chosen
}

/// Panics on failure
pub fn random_user(conn: pog.Connection) -> uuid.Uuid {
  let r_role = random_role()
  let role_to_enum = fn(role: role.Role) {
    case role {
      role.Admin -> u_sql.Admin
      role.Analyst -> u_sql.Analyst
      role.Captain -> u_sql.Captain
      role.Developer -> u_sql.Developer
      role.Firefighter -> u_sql.Firefighter
      role.Sargeant -> u_sql.Sargeant
    }
  }

  let assert Ok(returned) =
    u_sql.insert_new_user(
      conn,
      "USER " <> wisp.random_string(6),
      "M " <> wisp.random_string(6),
      uuid.v7_string(),
      wisp.random_string(8) <> "@email.com",
      uuid.v7_string(),
      role_to_enum(r_role),
    )
    as "Failed to create Dummy user"

  let assert Ok(row) = list.first(returned.rows)
  row.id
}

/// Panic on failure
pub fn clean_user(conn: pog.Connection, dummy: uuid.Uuid) -> Nil {
  let assert Ok(returned) = u_sql.delete_user_by_id(conn, dummy)
    as "Database has been accessed"

  let assert Ok(row) = list.first(returned.rows)
    as "Database returned row after deletion"

  assert row.id == dummy as "Deleted the correct user"
}

/// Panic on failure
pub fn clean_user_list(conn: pog.Connection, dummy: List(uuid.Uuid)) {
  let cleanup_participants = {
    use participant <- list.map(dummy)
    let assert Ok(returned) = u_sql.delete_user_by_id(conn, participant)
      as "Failed to delete participant"
    let assert Ok(row) = list.first(returned.rows)
      as "Database returned no results"

    row.id
  }

  assert cleanup_participants == dummy as "Deleted the wrong Participants"
}

/// Panic on failure
pub fn random_occurrence(
  conn conn: pog.Connection,
  applicant_id applicant_id: uuid.Uuid,
  assign dummy_brigade_list: List(uuid.Uuid),
) -> uuid.Uuid {
  let dummy_category = case random_category() {
    category.Fire -> o_sql.Fire
    category.MedicEmergency -> o_sql.MedicEmergency
    category.Other -> o_sql.Other
    category.TrafficAccident -> o_sql.TrafficAccident
  }

  let dummy_subcategory = case random_subcategory() {
    subcategory.Collision -> o_sql.Collision
    subcategory.Comercial -> o_sql.Comercial
    subcategory.Flood -> o_sql.Flood
    subcategory.HeartStop -> o_sql.HeartStop
    subcategory.InjuredAnimal -> o_sql.InjuredAnimal
    subcategory.Intoxication -> o_sql.Intoxication
    subcategory.MotorcycleCrash -> o_sql.MotorcycleCrash
    subcategory.PreHospitalCare -> o_sql.PreHospitalCare
    subcategory.Residential -> o_sql.Residential
    subcategory.Rollover -> o_sql.Rollover
    subcategory.RunOver -> o_sql.RunOver
    subcategory.Seizure -> o_sql.Seizure
    subcategory.SeriousInjury -> o_sql.SeriousInjury
    subcategory.TreeCrash -> o_sql.TreeCrash
    subcategory.Vegetation -> o_sql.Vegetation
    subcategory.Vehicle -> o_sql.Vehicle
  }

  let dummy_priority = case random_priority() {
    priority.High -> o_sql.High
    priority.Low -> o_sql.Low
    priority.Medium -> o_sql.Medium
  }

  let assert Ok(returned) =
    o_sql.insert_new_occurence(
      conn,
      applicant_id,
      dummy_category,
      dummy_subcategory,
      dummy_priority,
      "Description: " <> wisp.random_string(12),
      [float.random() *. 100.0, float.random() *. 100.0],
      "Next to: " <> wisp.random_string(12),
    )
    as "Database has been accessed"

  let assert Ok(created_occurrence_row) = list.first(returned.rows)
    as "Database returned results after registering occurrence"

  let assert Ok(assigned_brigades_row) =
    o_sql.assign_brigades_to_occurrence(
      conn,
      created_occurrence_row.id,
      dummy_brigade_list,
    )
    as "Brigades were assigned to occurrence"

  let dummy_brigades_set = set.from_list(dummy_brigade_list)
  let assigned_brigades_set =
    set.from_list({
      let rows = assigned_brigades_row.rows
      use row <- list.map(rows)
      row.inserted_brigade_id
    })

  assert set.difference(assigned_brigades_set, dummy_brigades_set)
    |> set.to_list()
    == []
    as "Assigned brigades contain unexpected items"

  assert set.difference(dummy_brigades_set, assigned_brigades_set)
    |> set.to_list()
    == []
    as "Some brigades were not assigned"

  created_occurrence_row.id
}

pub fn update_occurrence_status(
  occ: uuid.Uuid,
  ctx: context.Context,
  is_active: Bool,
) {
  let updated = case is_active {
    False -> {
      let assert Ok(returned) = o_sql.reopen_occurrence(ctx.db, occ)
      let assert Ok(row) = list.first(returned.rows)
      row.id
    }
    True -> {
      let assert Ok(returned) = o_sql.resolve_occurrence(ctx.db, occ)
      let assert Ok(row) = list.first(returned.rows)
      row.id
    }
  }

  assert occ == updated as "Update the correct occurrence"
}

/// Panic on failure
pub fn clean_occurrence(conn: pog.Connection, dummy: uuid.Uuid) {
  let assert Ok(returned) = o_sql.delete_occurrence_by_id(conn, dummy)
    as "DataBase has been accessed"
  let assert Ok(row) = list.first(returned.rows)
    as "DataBase returned row after deleting"

  assert row.id == dummy as "Deleted the wrong Occurrence"
}
