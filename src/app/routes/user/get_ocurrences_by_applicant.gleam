//// Handler for retrieving occurrences reported by a specific applicant.
////
//// It returns a list of occurrences (incidents/reports) that were submitted
//// by the specified user, including detailed information about each occurrence.

import app/routes/occurrence/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/time/timestamp
import pog
import wisp
import youid/uuid

/// Fetches all occurrences/applications associated with a specific user
/// from the database and returns them as JSON.
pub fn handle_request(
  request request: wisp.Request,
  ctx ctx: Context,
  id user_id: String,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  case query_occurrences(ctx:, user_id:) {
    Ok(occurrence_list) ->
      wisp.json_response(json.to_string(occurrence_list), 200)
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

  let occurence_list = {
    use row <- list.map(returned.rows)
    get_occurences_by_applicant_row_to_json(row)
  }

  Ok(json.preprocessed_array(occurence_list))
}

fn handle_error(err: GetOccurrencesByApplicantError) {
  case err {
    InvalidUUID(user_id) ->
      wisp.bad_request("ID de usuário inválido: " <> user_id)
    DataBaseError(err) -> {
      let internal_err_message = case err {
        pog.ConnectionUnavailable ->
          "Conexão com o Banco de Dados não disponível"
        pog.QueryTimeout -> "O Banco de Dados demorou muito para responder"
        _ -> "Ocorreu um erro ao realizar a consulta no Banco de Dados"
      }

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(internal_err_message))
    }
  }
}

/// Represents possible errors that can occur during the search
/// including invalid UUID formats for applicant
type GetOccurrencesByApplicantError {
  /// The provided applicant ID is not a valid UUID format
  InvalidUUID(String)
  /// An Error occurred when querying the database
  DataBaseError(pog.QueryError)
}

fn get_occurences_by_applicant_row_to_json(
  get_occurences_by_applicant_row: sql.QueryOccurencesByApplicantRow,
) -> json.Json {
  let sql.QueryOccurencesByApplicantRow(
    id:,
    description:,
    category:,
    subcategory:,
    created_at:,
    updated_at:,
    resolved_at:,
    location:,
    reference_point:,
  ) = get_occurences_by_applicant_row
  json.object([
    #("id", json.string(uuid.to_string(id))),
    #("description", json.nullable(description, json.string)),
    #("category", json.nullable(category, json.string)),
    #("subcategory", json.nullable(subcategory, json.string)),
    #("created_at", json.float(timestamp.to_unix_seconds(created_at))),
    #("updated_at", json.float(timestamp.to_unix_seconds(updated_at))),
    #("resolved_at", json.nullable(maybe_timestamp(resolved_at), json.float)),
    #("location", json.array(location, json.float)),
    #("reference_point", json.string(option.unwrap(reference_point, ""))),
  ])
}

fn maybe_timestamp(
  timestamp: option.Option(timestamp.Timestamp),
) -> option.Option(Float) {
  use time_stamp <- option.map(timestamp)
  timestamp.to_unix_seconds(time_stamp)
}
