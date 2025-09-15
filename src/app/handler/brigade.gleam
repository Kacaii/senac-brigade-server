import app/sql
import app/web.{type Context}
import gleam/http
import gleam/json
import gleam/list
import wisp
import youid/uuid

pub fn get_brigade_members(
  req: wisp.Request,
  ctx: Context,
  brigade_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
  let brigade_id_result = uuid.from_string(brigade_id)

  case brigade_id_result {
    Error(_) -> wisp.bad_request("ID de brigada inválido")
    Ok(brigade_id) -> {
      let brigade_members_result = sql.get_brigade_members(ctx.conn, brigade_id)

      case brigade_members_result {
        Ok(returned) -> {
          let brigade_members_rows = returned.rows
          let json_list = {
            use row <- list.map(brigade_members_rows)
            get_brigade_members_row_to_json(row)
          }

          let response = json.preprocessed_array(json_list) |> json.to_string()
          wisp.json_response(response, 200)
        }
        Error(_) -> wisp.no_content()
      }
    }
  }
}

fn get_brigade_members_row_to_json(
  get_brigade_members_row: sql.GetBrigadeMembersRow,
) -> json.Json {
  let sql.GetBrigadeMembersRow(full_name:, registration:) =
    get_brigade_members_row
  json.object([
    #("full_name", json.string(full_name)),
    #("registration", json.string(registration)),
  ])
}
