//// Handler for retrieving occurrences reported by a specific applicant.
////
//// It returns a list of occurrences (incidents/reports) that were submitted
//// by the specified user, including detailed information about each occurrence.

import app/routes/user/sql
import app/web
import gleam/float
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
  ctx ctx: web.Context,
  id user_id: String,
) -> wisp.Response {
  use <- wisp.require_method(request, http.Get)

  let query_result = {
    use user_uuid <- result.try(
      uuid.from_string(user_id)
      |> result.replace_error(InvalidUUID),
    )

    use returned <- result.try(
      sql.get_occurences_by_applicant(ctx.conn, user_uuid)
      |> result.map_error(DatabaseError),
    )

    let occurence_list = {
      use row <- list.map(returned.rows)
      get_occurences_by_applicant_row_to_json(row)
    }

    Ok(json.preprocessed_array(occurence_list))
  }

  case query_result {
    Ok(data) -> wisp.json_response(json.to_string(data), 200)
    Error(err) -> {
      case err {
        InvalidUUID -> wisp.bad_request("ID de usuário inválido")
        DatabaseError(err) -> {
          let internal_err_message = case err {
            pog.ConnectionUnavailable ->
              "Conexão com o Banco de Dados não disponível"
            pog.QueryTimeout ->
              "O banco de dados demorou muito para responder, talvez tenha perdido a conexão?"
            _ -> "Ocorreu um erro ao realizar a consulta no Banco de Dados"
          }

          wisp.internal_server_error()
          |> wisp.set_body(wisp.Text(internal_err_message))
        }
      }
    }
  }
}

/// Represents possible errors that can occur during the search
/// including invalid UUID formats for applicant
type GetOccurrencesByApplicantError {
  /// The provided applicant ID is not a valid UUID format
  InvalidUUID
  /// An Error occurred when querying the database
  DatabaseError(pog.QueryError)
}

fn get_occurences_by_applicant_row_to_json(
  get_occurences_by_applicant_row: sql.GetOccurencesByApplicantRow,
) -> json.Json {
  let sql.GetOccurencesByApplicantRow(
    id:,
    description:,
    category:,
    subcategory:,
    created_at:,
    resolved_at:,
    location:,
    reference_point:,
  ) = get_occurences_by_applicant_row
  json.object([
    #("id", json.string(uuid.to_string(id))),
    #("description", case description {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("category", case category {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("subcategory", case subcategory {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("created_at", case created_at {
      option.None -> json.null()
      option.Some(value) -> {
        timestamp.to_unix_seconds(value)
        |> float.to_string
        |> json.string
      }
    }),
    #("resolved_at", case resolved_at {
      option.None -> json.null()
      option.Some(value) -> {
        timestamp.to_unix_seconds(value)
        |> float.to_string
        |> json.string
      }
    }),
    #("location", json.array(location, json.float)),
    #("reference_point", json.string(option.unwrap(reference_point, ""))),
  ])
}
