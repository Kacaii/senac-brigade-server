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
  Database(pog.QueryError)
  AccessControl(user.AccessControlError)
}

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
    sql.occurrence_volume(ctx.db)
    |> result.map_error(Database),
  )

  returned.rows
  |> json.array(of: row_to_json)
  |> json.to_string
}

fn row_to_json(row: sql.OccurrenceVolumeRow) -> json.Json {
  let timestamp_to_json = fn(t: timestamp.Timestamp) {
    timestamp.to_unix_seconds(t) |> json.float
  }

  let maybe_timestamp_to_json = fn(t: option.Option(timestamp.Timestamp)) {
    case t {
      option.None -> json.null()
      option.Some(t) -> timestamp_to_json(t)
    }
  }

  let cat_to_json = fn(c: sql.OccurrenceCategoryEnum) {
    case c {
      sql.Fire -> category.Fire
      sql.MedicEmergency -> category.MedicEmergency
      sql.Other -> category.Other
      sql.TrafficAccident -> category.TrafficAccident
    }
    |> category.to_string
    |> json.string
  }

  let subcat_to_json = fn(s: option.Option(sql.OccurrenceSubcategoryEnum)) -> json.Json {
    case s {
      option.None -> json.null()
      option.Some(value) ->
        case value {
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
        |> subcategory.to_string
        |> json.string
    }
  }

  let maybe_role_to_json = fn(r: option.Option(sql.UserRoleEnum)) -> json.Json {
    case r {
      option.None -> json.null()
      option.Some(value) ->
        case value {
          sql.Admin -> role.Admin
          sql.Analyst -> role.Analyst
          sql.Captain -> role.Captain
          sql.Developer -> role.Developer
          sql.Firefighter -> role.Firefighter
          sql.Sargeant -> role.Sargeant
        }
        |> role.to_json
    }
  }

  let priority_to_json = fn(p: sql.OccurrencePriorityEnum) -> json.Json {
    case p {
      sql.High -> priority.High
      sql.Low -> priority.Low
      sql.Medium -> priority.Medium
    }
    |> priority.to_string
    |> json.string
  }

  json.object([
    #("occurrence_id", json.string(row.occurrence_id |> uuid.to_string)),
    #("reported_timestamp", timestamp_to_json(row.reported_timestamp)),
    #("arrival_timestamp", maybe_timestamp_to_json(row.arrival_timestamp)),
    #("resolved_timestamp", maybe_timestamp_to_json(row.resolved_timestamp)),
    #("occurrence_category", cat_to_json(row.occurrence_category)),
    #("occurrence_subcategory", subcat_to_json(row.occurrence_subcategory)),
    #("priority", priority_to_json(row.priority)),
    #("applicant_name", json.nullable(row.applicant_name, json.string)),
    #("applicant_role", maybe_role_to_json(row.applicant_role)),
    #("latitude", json.float(row.latitude)),
    #("longitude", json.float(row.longitude)),
  ])
}
