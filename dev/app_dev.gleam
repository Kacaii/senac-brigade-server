import app
import app/web/context.{type Context, Context}
import argv
import dummy
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import pog

/// Number of generated user accounts
const n_user_accounts = 450

/// Number of generated brigades
const n_brigades = 30

/// Number of generated brigades
const n_occurences = 200

pub fn main() -> Nil {
  let ctx = setup_context()

  case argv.load().arguments {
    ["admin"] -> app.setup_admin(ctx)
    ["dummy"] -> dummy_data(ctx)
    _ -> Nil
  }
}

fn dummy_data(ctx: Context) {
  io.println("   Inserindo usuários..")

  let dummy_users =
    list.map(list.range(1, n_user_accounts), fn(_) { dummy.random_user(ctx.db) })

  // BRIGADES ------------------------------------------------------------------
  io.println("   Formando equipes..")

  let assigned_members =
    list.shuffle(dummy_users)
    |> list.sized_chunk(n_user_accounts / n_brigades)

  let dummy_brigades =
    list.map(assigned_members, fn(team) {
      let assert Ok(leader) = list.first(team)
      dummy.random_brigade(ctx.db, leader, team)
    })

  let assigned_brigades =
    list.shuffle(dummy_brigades)
    |> list.sized_chunk(n_occurences / n_brigades)

  io.println(" 󱐁  Registrando ocorrências..")
  let dummy_occurrences =
    list.map(list.range(1, n_occurences), fn(_) {
      let assert Ok(applicant_id) = list.first(list.sample(dummy_users, 1))
      let assert Ok(assign) = list.first(list.sample(assigned_brigades, 1))
      dummy.random_occurrence(conn: ctx.db, applicant_id:, assign:)
    })

  // ALL DONE ------------------------------------------------------------------
  let n_created_brigades_str =
    dummy_brigades
    |> list.length
    |> int.to_string

  let n_created_users_str =
    dummy_users
    |> list.length
    |> int.to_string

  let n_created_occ_str =
    dummy_occurrences
    |> list.length
    |> int.to_string

  io.println("   Prontinho!")
  io.println("Total de " <> n_created_users_str <> " usuários criados.  ")
  io.println("Total de " <> n_created_brigades_str <> " equipes criadas.  ")
  io.println("Total de " <> n_created_occ_str <> " ocorrências criadas.  ")
}

fn setup_context() {
  let db_process_name = process.new_name("db_conn")
  let registry_name = process.new_name("registry")

  let assert Ok(config) = app.read_connection_uri(db_process_name)
  let assert Ok(secret_key_base) = app.read_cookie_token()

  let db = pog.named_connection(db_process_name)
  let assert Ok(_) = pog.start(config)

  Context(
    static_directory: app.static_directory(),
    db:,
    registry_name:,
    secret_key_base:,
  )
}
