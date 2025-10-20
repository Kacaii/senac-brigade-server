//// Handler for retrieving occurrences reported by a specific applicant.
////
//// It returns a list of occurrences (incidents/reports) that were submitted
//// by the specified user, including detailed information about each occurrence.

import app/database
import app/routes/occurrence/category
import app/routes/occurrence/priority
import app/routes/occurrence/sql
import app/web.{type Context}
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/time/timestamp
import pog
import wisp
import youid/uuid

/// 󰡦  Find all occurrences/applications associated with a specific user
/// returns them as formatted JSON data
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
  id user_id: String,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  case query_occurrences(ctx:, user_id:) {
    Ok(data) -> wisp.json_response(json.to_string(data), 200)
    Error(err) -> handle_error(err)
  }
}

fn query_occurrences(ctx ctx: Context, user_id user_id: String) {
  use user_uuid <- result.try(
    uuid.from_string(user_id)
    |> result.replace_error(InvalidUUID(user_id)),
  )

  use returned <- result.try(
    sql.query_occurences_by_applicant(ctx.conn, user_uuid)
    |> result.map_error(DataBaseError),
  )

  let payload_result = {
    use row <- list.try_map(returned.rows)

    // DECODER FOR BRIGADES
    use brigade_list <- result.map(
      brigade_list_decoder(row.brigade_list)
      |> result.map_error(BrigadeListDecodeError),
    )

    Payload(
      id: row.applicant_id,
      status: case row.resolved_at {
        option.None -> "Em andamento"
        option.Some(_) -> "Finalizada"
      },
      priority: enum_to_priority(row.priority),
      call: PayloadCall(
        category: enum_to_category(row.occurrence_category),
        details: row.details,
        applicant_name: row.applicant_name,
      ),
      occurrence_location: row.occurrence_location,
      timestamp: PayloadTimestamp(
        created_at: row.created_at,
        arrival_in_place: row.arrived_at,
        resolved_at: row.arrived_at,
      ),
      metadata: PayloadMetadata(
        applicant_id: row.applicant_id,
        applicant_registration: row.applicant_registration,
        applicant_name: row.applicant_name,
      ),
      brigade_list: brigade_list,
    )
    |> payload_to_json()
  }

  case payload_result {
    Ok(value) -> Ok(json.preprocessed_array(value))
    Error(value) -> Error(value)
  }
}

fn brigade_list_decoder(data: String) {
  json.parse(data, {
    // UUID Decoder
    let brigade_uuid_decoder = {
      use maybe_uuid <- decode.then(decode.string)
      case uuid.from_string(maybe_uuid) {
        Error(_) -> decode.failure(uuid.v7(), "brigade_uuid")
        Ok(value) -> decode.success(value)
      }
    }

    decode.list({
      use brigade_id <- decode.field("id", brigade_uuid_decoder)
      use leader_name <- decode.field("leader_full_name", decode.string)
      use vehicle_code <- decode.field("vehicle_code", decode.string)

      decode.success(PayloadBrigade(
        id: brigade_id,
        vehicle_code: vehicle_code,
        leader_name: leader_name,
      ))
    })
  })
}

fn handle_error(err: GetOccurrencesByApplicantError) {
  case err {
    InvalidUUID(user_id) ->
      wisp.bad_request("ID de usuário inválido: " <> user_id)
    DataBaseError(err) -> database.handle_database_error(err)
    BrigadeListDecodeError(_) ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "Não foi possível decodificar a lista de equipes",
      ))
  }
}

fn enum_to_priority(enum: sql.OccurrencePriorityEnum) {
  case enum {
    sql.High -> priority.High
    sql.Low -> priority.Low
    sql.Medium -> priority.Medium
  }
}

fn enum_to_category(enum: sql.OccurrenceCategoryEnum) -> category.Category {
  case enum {
    sql.Other -> category.Other
    sql.TrafficAccident -> category.TrafficAccident
    sql.Fire -> category.Fire
    sql.MedicEmergency -> category.MedicEmergency
  }
}

/// Represents possible errors that can occur during the search
/// including invalid UUID formats for applicant
type GetOccurrencesByApplicantError {
  /// The provided applicant ID is not a valid UUID format
  InvalidUUID(String)
  /// An Error occurred when querying the database
  DataBaseError(pog.QueryError)
  BrigadeListDecodeError(json.DecodeError)
}

// PAYLOAD -------------------------------------------------------------------------------------------------------------

pub type Payload {
  Payload(
    id: uuid.Uuid,
    status: String,
    priority: priority.Priority,
    call: PayloadCall,
    occurrence_location: List(Float),
    timestamp: PayloadTimestamp,
    metadata: PayloadMetadata,
    brigade_list: List(PayloadBrigade),
  )
}

fn payload_to_json(data: Payload) -> json.Json {
  json.object([
    #("id", json.string(uuid.to_string(data.id))),
    #("status", json.string(data.status)),
    #("prioridade", json.string(priority.to_string_pt_br(data.priority))),
    #("chamado", payload_call_to_json(data.call)),
    #("coordenadas", json.array(data.occurrence_location, json.float)),
    #("timestamps", payload_timestamp_to_json(data.timestamp)),
    #("metadata", payload_metadata_to_json(data.metadata)),
    #("equipes", payload_brigade_list_to_json(data.brigade_list)),
  ])
}

pub opaque type PayloadCall {
  PayloadCall(
    category: category.Category,
    details: option.Option(String),
    applicant_name: String,
  )
}

fn payload_call_to_json(data: PayloadCall) -> json.Json {
  json.object([
    #("tipo", json.string(category.to_string_pt_br(data.category))),
    #("detalhes", json.string(option.unwrap(data.details, ""))),
    #("solicitante", json.object([#("nome", json.string(data.applicant_name))])),
  ])
}

pub opaque type PayloadTimestamp {
  PayloadTimestamp(
    created_at: timestamp.Timestamp,
    arrival_in_place: option.Option(timestamp.Timestamp),
    resolved_at: option.Option(timestamp.Timestamp),
  )
}

fn payload_timestamp_to_json(data: PayloadTimestamp) -> json.Json {
  json.object([
    #("abertura", json.float(timestamp.to_unix_seconds(data.created_at))),
    #(
      "chegadaNoLocal",
      json.nullable(
        option.map(data.arrival_in_place, timestamp.to_unix_seconds),
        json.float,
      ),
    ),
    #(
      "finalizacao",
      json.nullable(
        option.map(data.resolved_at, timestamp.to_unix_seconds),
        json.float,
      ),
    ),
  ])
}

pub opaque type PayloadMetadata {
  PayloadMetadata(
    applicant_id: uuid.Uuid,
    applicant_registration: String,
    applicant_name: String,
  )
}

fn payload_metadata_to_json(data: PayloadMetadata) -> json.Json {
  json.object([
    #("nomeUsuario", json.string(data.applicant_name)),
    #("matriculaUsuario", json.string(data.applicant_registration)),
    #("usuarioId", json.string(uuid.to_string(data.applicant_id))),
  ])
}

pub opaque type PayloadBrigade {
  PayloadBrigade(id: uuid.Uuid, vehicle_code: String, leader_name: String)
}

fn payload_brigade_list_to_json(data: List(PayloadBrigade)) -> json.Json {
  json.preprocessed_array(
    list.map(data, fn(row) {
      json.object([
        #("id", json.string(row.vehicle_code)),
        #("lider", json.string(row.leader_name)),
        #("codigoViatura", json.string(row.vehicle_code)),
      ])
    }),
  )
}
