alias b := build
alias r := run
alias s := squirrel
alias t := test
alias u := update
alias wr := watch_run
alias wt := watch_test

# Print recipes list
@default:
    just --list

#   Update project dependencies
update:
    gleam deps update

#   Run the project
run:
    gleam run

#   Generate SQL
squirrel:
    gleam run -m squirrel

# 󰜉  Rebuild the database from the ground up
rebuild:
  psql senac_brigade -f priv/sql/rebuild_database.sql

# 󰙨  Run all unit tests
test:
    gleam test

# 󰏓  Builds the project for production
build:
    gleam export erlang-shipment

#   Watch for file changes and run the project
watch_run:
    watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam --debounce 500ms --watch src/ -- "clear; gleam run"

#   Watch for file changes and run unit tests
watch_test:
    watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam --debounce 500ms --watch src/ -- "clear; gleam run"
