import app/routes/admin/sql
import app/routes/user/sql as user_sql
import app/web
import app/web/context.{type Context}
import argus
import envoy
import gleam/dynamic/decode
import gleam/http
import gleam/list
import gleam/result
import pog
import wisp

const admin_registration = "000"

const admin_password = "aluno"

///   Generate the first admin user
pub fn handle_request(
  request req: wisp.Request,
  ctx ctx: Context,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)
  use json_data <- wisp.require_json(req)

  case decode.run(json_data, key_decoder()) {
    Error(_) ->
      wisp.unprocessable_content()
      |> wisp.set_body(wisp.Text("Chave Secreta ausente"))
    Ok(key) ->
      case validate_admin_key(ctx, key) {
        Error(err) -> handle_error(err)
        Ok(_) -> insert_first_admin(ctx)
      }
  }
}

fn insert_first_admin(ctx: Context) -> wisp.Response {
  let insert_result = {
    use hashed_password <- result.try(
      argus.hasher()
      |> argus.hash(admin_password, argus.gen_salt())
      |> result.replace_error(HashError),
    )

    use _ <- result.try(
      user_sql.insert_new_user(
        ctx.db,
        "Drop Table da Silva",
        admin_registration,
        "0000000000",
        "admin@email.com",
        hashed_password.encoded_hash,
        user_sql.Admin,
      )
      |> result.map_error(DataBaseError),
    )

    // No need to return anything from this function
    Ok(Nil)
  }

  case insert_result {
    Ok(_) ->
      wisp.created()
      |> wisp.set_body(wisp.Text("Primeiro admin criado com sucesso!"))
    Error(err) -> handle_error(err)
  }
}

fn handle_error(err: SetupAdminError) -> wisp.Response {
  case err {
    DataBaseNotEmpty ->
      wisp.bad_request(
        "O banco de dados precisa estar com a tabela de usuários vazia",
      )
    DataBaseReturnedEmptyRow(_) ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "Não foi possível consultar o número total de usuários cadastrados",
      ))

    HashError ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "Ocorreu um erro ao encriptografar a senha do usuário",
      ))
    IncorrectRequestToken(_) ->
      wisp.response(403)
      |> wisp.set_body(wisp.Text("Token Inválido"))
    MissingEnvToken ->
      wisp.internal_server_error()
      |> wisp.set_body(wisp.Text(
        "A variável de ambiente necessária para o acesso a este endpoint se encontra ausente",
      ))

    DataBaseError(err) -> web.handle_database_error(err)
  }
}

fn validate_admin_key(ctx: Context, key: String) -> Result(Nil, SetupAdminError) {
  use admin_token <- result.try(
    envoy.get("ADMIN_TOKEN")
    |> result.replace_error(MissingEnvToken),
  )

  use returned <- result.try(
    sql.count_total_users(ctx.db)
    |> result.map_error(DataBaseError),
  )

  use row <- result.try(
    list.first(returned.rows)
    |> result.map_error(DataBaseReturnedEmptyRow),
  )

  case key == admin_token, row.total {
    // Correct token, empty database
    True, 0 -> Ok(Nil)
    // Invalid token
    False, _ -> Error(IncorrectRequestToken(key))
    // Database already have some user
    _, _ -> Error(DataBaseNotEmpty)
  }
}

fn key_decoder() -> decode.Decoder(String) {
  use key <- decode.field("key", decode.string)
  decode.success(key)
}

type SetupAdminError {
  IncorrectRequestToken(String)
  MissingEnvToken
  DataBaseError(pog.QueryError)
  DataBaseReturnedEmptyRow(Nil)
  DataBaseNotEmpty
  HashError
}
