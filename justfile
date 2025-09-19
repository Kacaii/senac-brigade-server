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
[group('  gleam')]
update:
    gleam deps update

#   Run the project
[group('  gleam')]
run:
    gleam run

#   Generate SQL
[group('  gleam')]
squirrel:
    gleam run -m squirrel

# 󰜉  Rebuild an empty database
[group('  postgres')]
rebuild:
    psql senac_brigade -f priv/sql/rebuild_database.sql

#   Insert the basic categories
[group('  postgres')]
insert_categories:
    psql senac_brigade -f priv/sql/insert_occurrence_categories.sql

# 󰜉 Rebuild the database with values in it
[group('  postgres')]
rebuild_full:
    just rebuild
    just insert_categories

# 󰙨  Run all unit tests
[group('  gleam')]
test:
    gleam test

# 󰏓  Builds the project for production
[group('  gleam')]
build:
    gleam export erlang-shipment

#   Watch for file changes and run the project
[group('  gleam')]
watch_run:
    watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam --debounce 500ms --watch src/ -- "clear; gleam run"

#   Watch for file changes and run unit tests
[group('  gleam')]
watch_test:
    watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam --debounce 500ms --watch src/ -- "clear; gleam run"

#   Runs a SELECT statement to query the users
[group('  postgres')]
[group('  query')]
list_user_accounts:
    psql senac_brigade -c "SELECT u.full_name, u.registration, u.phone, u.email FROM user_account as u LIMIT 20;" | bat --language=markdown

#   Runs a SELECT statement to query the occurrence caregories
[group('  postgres')]
[group('  query')]
list_occurrence_categories:
    psql senac_brigade -c "SELECT c.category_name, c.description from occurrence_category as c LIMIT 20;" | bat --language=markdown
