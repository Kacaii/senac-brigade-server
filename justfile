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
create_tables:
    psql senac_brigade -f priv/sql/rebuild_database.sql

insert_categories:
    psql senac_brigade -f priv/sql/insert_occurrence_categories.sql

rebuild_full:
    just create_tables
    just insert_categories

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

#   Runs a SELECT statement to query the users
list_user_accounts:
    psql senac_brigade -c "SELECT u.full_name, u.registration, u.phone, u.email FROM user_account as u LIMIT 20;" | bat --language=markdown

list_occurrence_categories:
    psql senac_brigade -c "SELECT c.category_name, c.description from occurrence_category as c LIMIT 20;" | bat --language=markdown
