import app/domain/data_analysis/sql
import app/domain/occurrence/category
import app/domain/occurrence/priority
import app/domain/occurrence/subcategory
import app/domain/role
import app/domain/user
import app/web
import app/web/context.{type Context}
import gleam/http
import gleam/json
import gleam/option
import gleam/result
import gleam/time/timestamp
import pog
import wisp
import youid/uuid

type AnalysisError {
  /// Failed to query the DataBase
  Database(pog.QueryError)
  /// User does not have access to this endpoint
  AccessControl(user.AccessControlError)
}

/// 󰕮  Retrieve general information about occurrences and send it as JSON
///
/// ## Response
///
/// ```jsonc
/// [
///   {
///     "occurrence_id": "019b19c2-8311-799c-99db-3f777732df4a",
///     "reported_timestamp": 1765652936.593211,
///     "arrival_timestamp": null,
///     "resolved_timestamp": null,
///     "occurrence_category": "fire",
///     "occurrence_subcategory": "injured_animal",
///     "priority": "high",
///     "applicant_name": "João Fulano",
///     "applicant_role": "analyst",
///     "latitude": 6.906980184619583,
///     "longitude": 75.57821949630532
///   }
/// ]
/// ```
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case query_database(req, ctx) {
    Error(err) -> handle_error(err, req)
    Ok(body) -> wisp.json_response(body, 200)
  }
}

fn handle_error(err: AnalysisError, req: wisp.Request) -> wisp.Response {
  case err {
    Database(err) -> web.handle_database_error(err)
    AccessControl(err) -> user.handle_access_control_error(req, err)
  }
}

fn query_database(req: wisp.Request, ctx: Context) {
  use _ <- result.try(
    user.check_role_authorization(
      request: req,
      ctx:,
      cookie_name: user.uuid_cookie_name,
      authorized_roles: [role.Admin, role.Developer, role.Analyst],
    )
    |> result.map_error(AccessControl),
  )

  use returned <- result.map(
    sql.occurrence_dataset(ctx.db)
    |> result.map_error(Database),
  )

  returned.rows
  |> json.array(of: row_to_json)
  |> json.to_string
}

fn row_to_json(row: sql.OccurrenceDatasetRow) -> json.Json {
  let timestamp_to_json = fn(t: timestamp.Timestamp) {
    timestamp.to_unix_seconds(t)
    |> json.float
  }

  let category = {
    case row.occurrence_category {
      sql.Fire -> category.Fire
      sql.MedicEmergency -> category.MedicEmergency
      sql.Other -> category.Other
      sql.TrafficAccident -> category.TrafficAccident
    }
  }

  let subcategory = {
    use subcategory <- option.map(row.occurrence_subcategory)
    case subcategory {
      sql.Collision -> subcategory.Collision
      sql.Comercial -> subcategory.Comercial
      sql.Flood -> subcategory.Flood
      sql.HeartStop -> subcategory.HeartStop
      sql.InjuredAnimal -> subcategory.InjuredAnimal
      sql.Intoxication -> subcategory.Intoxication
      sql.MotorcycleCrash -> subcategory.MotorcycleCrash
      sql.PreHospitalCare -> subcategory.PreHospitalCare
      sql.Residential -> subcategory.Residential
      sql.Rollover -> subcategory.Rollover
      sql.RunOver -> subcategory.RunOver
      sql.Seizure -> subcategory.Seizure
      sql.SeriousInjury -> subcategory.SeriousInjury
      sql.TreeCrash -> subcategory.TreeCrash
      sql.Vegetation -> subcategory.Vegetation
      sql.Vehicle -> subcategory.Vehicle
    }
  }

  let role = {
    use role <- option.map(row.applicant_role)
    case role {
      sql.Admin -> role.Admin
      sql.Analyst -> role.Analyst
      sql.Captain -> role.Captain
      sql.Developer -> role.Developer
      sql.Firefighter -> role.Firefighter
      sql.Sargeant -> role.Sargeant
    }
  }

  let priority = case row.priority {
    sql.High -> priority.High
    sql.Low -> priority.Low
    sql.Medium -> priority.Medium
  }

  let arrival_timestamp_json =
    json.nullable(row.arrival_timestamp, timestamp_to_json)

  let resolved_timestamp_json =
    json.nullable(row.resolved_timestamp, timestamp_to_json)

  json.object([
    #("occurrence_id", json.string(row.occurrence_id |> uuid.to_string)),
    #("reported_timestamp", timestamp_to_json(row.reported_timestamp)),
    #("arrival_timestamp", arrival_timestamp_json),
    #("resolved_timestamp", resolved_timestamp_json),
    #("occurrence_category", category.to_json(category)),
    #("occurrence_subcategory", json.nullable(subcategory, subcategory.to_json)),
    #("priority", priority.to_json(priority)),
    #("applicant_name", json.nullable(row.applicant_name, json.string)),
    #("applicant_role", json.nullable(role, role.to_json)),
    #("latitude", json.float(row.latitude)),
    #("longitude", json.float(row.longitude)),
  ])
}
