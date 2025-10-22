import app/web
import gleam/json
import pog
import wisp

pub fn handle_database_error(err: pog.QueryError) -> wisp.Response {
  case err {
    pog.ConnectionUnavailable ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text("Conexão com o Banco de Dados não disponível"))

    pog.ConstraintViolated(message:, constraint:, detail:) -> {
      let body =
        json.object([
          #("message", json.string(message)),
          #("constrain", json.string(constraint)),
          #("detail", json.string(detail)),
        ])
        |> json.to_string()

      wisp.json_response(body, 500)
    }

    pog.QueryTimeout ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "O Banco de Dados demorou muito para responder",
      ))

    pog.PostgresqlError(code:, name:, message:) -> {
      let body =
        json.object([
          #("code", json.string(code)),
          #("name", json.string(name)),
          #("message", json.string(message)),
        ])
        |> json.to_string()

      wisp.json_response(body, 500)
    }

    pog.UnexpectedArgumentCount(expected:, got:) -> {
      let body =
        json.object([
          #("expected", json.int(expected)),
          #("got", json.int(got)),
        ])
        |> json.to_string()

      wisp.json_response(body, 500)
    }

    pog.UnexpectedArgumentType(expected:, got:) -> {
      let body =
        json.object([
          #("expected", json.string(expected)),
          #("got", json.string(got)),
        ])
        |> json.to_string()

      wisp.json_response(body, 500)
    }
    pog.UnexpectedResultType(err) -> web.handle_decode_error(err)
  }
}
