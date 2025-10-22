import app
import app/router
import app/web
import argv
import dummy
import gleam/erlang/process
import gleam/http
import gleam/io
import gleam/json
import gleam/list
import pog
import simplifile
import wisp/simulate

const n_user_accounts = 100

pub fn main() -> Nil {
  let ctx = setup_context()

  case argv.load().arguments {
    ["rebuild"] -> rebuild_db(ctx)
    ["dummy"] -> dummy_users(ctx)
    _ -> Nil
  }
}

fn rebuild_db(ctx: web.Context) -> Nil {
  // FILES ---------------------------------------------------------------------
  let assert Ok(sql_drop) = simplifile.read("../priv/sql/drop.sql")
  let assert Ok(sql_tables) = simplifile.read("../priv/sql/create/tables.sql")
  let assert Ok(sql_triggers) =
    simplifile.read("../priv/sql/create/triggers.sql")
  let assert Ok(sql_functions) =
    simplifile.read("../priv/sql/create/functions.sql")
  let assert Ok(sql_views) = simplifile.read("../priv/sql/create/views.sql")

  // QUERIES -------------------------------------------------------------------
  let assert Ok(_) =
    pog.query(sql_drop)
    |> pog.execute(ctx.conn)

  let assert Ok(_) =
    pog.query(sql_tables)
    |> pog.execute(ctx.conn)

  let assert Ok(_) =
    pog.query(sql_triggers)
    |> pog.execute(ctx.conn)

  let assert Ok(_) =
    pog.query(sql_functions)
    |> pog.execute(ctx.conn)

  let assert Ok(_) =
    pog.query(sql_views)
    |> pog.execute(ctx.conn)

  setup_admin(ctx)
}

fn setup_admin(ctx: web.Context) {
  let setup_admin_req =
    simulate.browser_request(http.Post, "/admin/setup")
    |> simulate.json_body(json.object([#("key", json.string("admin"))]))

  let resp = router.handle_request(setup_admin_req, ctx)
  assert resp.status == 201 as "Failed to create first Admin"
}

fn dummy_users(ctx: web.Context) {
  io.println("   Inserindo usuários..")
  let dummy_users =
    list.map(list.range(0, n_user_accounts - 1), fn(_) {
      dummy.random_user(ctx)
    })

  // BRIGADES ------------------------------------------------------------------
  io.println("   Formando equipes..")
  let teams =
    list.shuffle(dummy_users)
    |> list.sized_chunk(n_user_accounts / 10)

  list.map(teams, fn(team) {
    let assert Ok(leader) = list.first(team)
    dummy.random_brigade(ctx, leader, team)
  })

  // ALL DONE ------------------------------------------------------------------
  io.println("   Prontinho!")
}

fn setup_context() {
  let db_process_name = process.new_name("db_conn")
  let assert Ok(config) = app.read_connection_uri(db_process_name)

  let conn = pog.named_connection(db_process_name)
  let assert Ok(_) = pog.start(config)

  web.Context(static_directory: app.static_directory(), conn:)
}
