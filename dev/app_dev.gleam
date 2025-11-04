import app
import app/web
import argv
import dummy
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import pog

const n_brigades = 30

const n_user_accounts = 450

pub fn main() -> Nil {
  let ctx = setup_context()

  case argv.load().arguments {
    ["admin"] -> app.setup_admin(ctx)
    ["dummy"] -> dummy_data(ctx)
    _ -> Nil
  }
}

fn dummy_data(ctx: web.Context) {
  io.println("   Inserindo usuários..")

  let dummy_users =
    list.map(list.range(1, n_user_accounts), fn(_) { dummy.random_user(ctx) })

  // BRIGADES ------------------------------------------------------------------
  io.println("   Formando equipes..")

  let assigned_members =
    list.shuffle(dummy_users)
    |> list.sized_chunk(n_user_accounts / n_brigades)

  let teams =
    list.map(assigned_members, fn(team) {
      let assert Ok(leader) = list.first(team)
      dummy.random_brigade(ctx, leader, team)
    })

  // ALL DONE ------------------------------------------------------------------
  let n_created_teams_str =
    teams
    |> list.length
    |> int.to_string

  let n_created_users_str =
    dummy_users
    |> list.length
    |> int.to_string

  io.println("   Prontinho!")
  io.println("Total de " <> n_created_users_str <> " usuários criados.  ")
  io.println("Total de " <> n_created_teams_str <> " equipes criadas.  ")
}

fn setup_context() {
  let db_process_name = process.new_name("db_conn")
  let assert Ok(config) = app.read_connection_uri(db_process_name)

  let conn = pog.named_connection(db_process_name)
  let assert Ok(_) = pog.start(config)

  web.Context(static_directory: app.static_directory(), conn:)
}
