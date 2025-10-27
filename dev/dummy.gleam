//// For testing purposes only

import app/routes/brigade/sql as b_sql
import app/routes/occurrence/category
import app/routes/occurrence/priority
import app/routes/occurrence/sql as o_sql
import app/routes/occurrence/subcategory
import app/routes/role
import app/routes/user/sql as u_sql
import app/web
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/set
import wisp
import youid/uuid

/// Panics on failure
pub fn random_role() -> role.Role {
  let samples =
    dict.from_list([
      #(0, role.Firefighter),
      #(1, role.Admin),
      #(2, role.Analyst),
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
  leader_id leader_id: uuid.Uuid,
  members dummy_members: List(uuid.Uuid),
) {
  let assert Ok(returned) =
    b_sql.insert_new_brigade(
      ctx.conn,
      leader_id,
      "BRIGADE " <> wisp.random_string(4),
      "VEHICLE " <> wisp.random_string(3),
      True,
    )
    as "Failed to create dummy brigade"

  let assert Ok(inserted_brigade_row) = list.first(returned.rows)
    as "Database returned no results after creating new Brigade"

  let assigments =
    list.map(dummy_members, fn(member_id) {
      //
      let assert Ok(returned) =
        b_sql.assign_brigade_member(
          ctx.conn,
          inserted_brigade_row.id,
          member_id,
        )
        as "Failed to assign Brigade Member"
      //
      let assert Ok(id) = list.first(returned.rows)
        as "No results after assigning brigade member"

      id
    })

  let assigned_members = list.map(assigments, fn(value) { value.user_id })

  let assigned_members_set = set.from_list(assigned_members)
  let dummy_members_set = set.from_list(dummy_members)

  assert set.difference(assigned_members_set, dummy_members_set)
    |> set.to_list
    == []
    as "Returned members contain unexpected users"

  assert set.difference(dummy_members_set, assigned_members_set)
    |> set.to_list
    == []
    as "Some brigade members were not returned"

  inserted_brigade_row.id
}

/// Panic on failure
pub fn clean_brigade(ctx: web.Context, dummy: uuid.Uuid) {
  let cleanup_brigade_id = {
    let assert Ok(returned) = b_sql.delete_brigade_by_id(ctx.conn, dummy)
      as "Failed to delete dummy brigade"

    let assert Ok(row) = list.first(returned.rows)
      as "Not results after deleting a brigade"

    row.id
  }

  assert cleanup_brigade_id == dummy as "Deleted the wrong Brigade"
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
      role.Analyst -> u_sql.Analyst
      role.Captain -> u_sql.Captain
      role.Developer -> u_sql.Developer
      role.Firefighter -> u_sql.Firefighter
      role.Sargeant -> u_sql.Sargeant
    }
  }

  let assert Ok(returned) =
    u_sql.insert_new_user(
      ctx.conn,
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
pub fn clean_user(ctx: web.Context, dummy: uuid.Uuid) {
  let assert Ok(cleanup_applicant) = {
    let assert Ok(returned) = u_sql.delete_user_by_id(ctx.conn, dummy)
      as "Failed to cleanup dummy user"

    list.first(returned.rows)
  }

  assert cleanup_applicant.id == dummy as "Deleted the wrong User"
}

/// Panic on failure
pub fn clean_user_list(ctx: web.Context, dummy: List(uuid.Uuid)) {
  let cleanup_participants = {
    use participant <- list.map(dummy)
    let assert Ok(returned) = u_sql.delete_user_by_id(ctx.conn, participant)
      as "Failed to delete participant"
    let assert Ok(row) = list.first(returned.rows)
      as "Database returned no results"

    row.id
  }

  assert cleanup_participants == dummy as "Deleted the wrong Participants"
}

/// Panic on failure
pub fn random_occurrence(
  ctx: web.Context,
  applicant_id applicant_id: uuid.Uuid,
  brigade_list brigade_list: List(uuid.Uuid),
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
      ctx.conn,
      applicant_id,
      dummy_category,
      dummy_subcategory,
      dummy_priority,
      "Description: " <> wisp.random_string(12),
      [float.random() *. 100.0, float.random() *. 100.0],
      "Next to: " <> wisp.random_string(12),
    )
    as "Failed to generate a dummy Occurrence"

  let assert Ok(row) = list.first(returned.rows)
    as "Database returned no results"

  let assert Ok(_) =
    list.try_each(brigade_list, fn(id) {
      o_sql.assign_brigade_to_occurrence(ctx.conn, row.id, id)
    })
    as "Failed to assign brigade to occurrence"

  row.id
}

/// Panic on failure
pub fn clean_occurrence(ctx: web.Context, dummy: uuid.Uuid) {
  let assert Ok(cleanup_occurrence) = {
    let assert Ok(returned) = o_sql.delete_occurrence_by_id(ctx.conn, dummy)
      as "Failed to cleanup dummy occurrence"
    list.first(returned.rows)
  }

  assert cleanup_occurrence.id == dummy as "Deleted the wrong Occurrence"
}
