import gleam/int
import pog
import wisp

pub fn handle_database_error(err: pog.QueryError) -> wisp.Response {
  case err {
    pog.ConnectionUnavailable ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text("Conexão com o Banco de Dados não disponível"))

    pog.ConstraintViolated(message:, constraint:, detail:) -> {
      wisp.bad_request(
        "Uma restrição foi encontrada no Banco de Dados: "
        <> constraint
        <> "\n"
        <> message
        <> "\n"
        <> detail,
      )
    }

    pog.QueryTimeout ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "O Banco de Dados demorou muito para responder",
      ))

    pog.PostgresqlError(code:, name:, message:) -> {
      let err_msg = code <> ": " <> name <> "\n" <> message
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(err_msg))
    }

    pog.UnexpectedArgumentCount(expected:, got:) -> {
      let err_msg =
        "Número de argumentos inválido\n"
        <> "Esperava:"
        <> int.to_string(expected)
        <> " Recebeu: "
        <> int.to_string(got)

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(err_msg))
    }

    pog.UnexpectedArgumentType(expected:, got:) -> {
      let err_msg =
        "Tipo de argumento inválido\n"
        <> "Esperava:"
        <> expected
        <> " Recebeu: "
        <> got

      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text(err_msg))
    }
    pog.UnexpectedResultType(_) -> {
      let err_msg =
        "Não foi possível decodificar o resultado retornado pelo Banco de Dados"

      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(err_msg))
    }
  }
}
