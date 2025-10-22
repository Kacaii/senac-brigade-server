log_file_path := 'priv/log/server.log'

alias r := rebuild_full
alias s := squirrel
alias u := update

# Print recipes list
@default:
    just --list

#   Update project dependencies
[group('  gleam')]
update:
    gleam deps update

#   Generate code from SQL files
[group('  gleam')]
[group('  dev')]
squirrel:
    gleam run -m squirrel

# 󰙨  Run unit tests
[group('  gleam')]
[group('  dev')]
test:
    gleam test

# 󱌢  Run dev script
[group('  gleam')]
[group('  dev')]
dev:
    gleam dev

# 󰏓  Builds the project for production
[group('  ship')]
[group('  gleam')]
build:
    gleam export erlang-shipment

#   Runs erlang-shipment entrypoint
[group('  ship')]
prod:
    ./build/erlang-shipment/entrypoint.sh run

# 󰜉  Rebuild the database
[group('  postgres')]
[group('  dev')]
@rebuild_empty:
    just clear_log_file
    psql $DATABASE_URL -f priv/sql/drop.sql
    psql $DATABASE_URL -f priv/sql/create/tables.sql
    psql $DATABASE_URL -f priv/sql/create/triggers.sql
    psql $DATABASE_URL -f priv/sql/create/functions.sql
    psql $DATABASE_URL -f priv/sql/create/views.sql

[group('  dev')]
@rebuild_full:
    just rebuild_empty
    just setup_admin

[group('  gleam')]
[group('  dev')]
setup_admin:
    gleam dev -- admin

[group('  dev')]
clean_users:
    psql $DATABASE_URL -c "delete from user_account where registration != '000';"

#   Runs a SELECT statement to query the user accounts
[group('  postgres')]
[group('  dev')]
[group('󰤏  query')]
list_user_accounts:
    psql $DATABASE_URL -f priv/sql/query/dev_list_user_accounts.sql

#   Runs a SELECT statement to query the briagdes
[group('  postgres')]
[group('  dev')]
[group('󰤏  query')]
list_brigades:
    psql $DATABASE_URL -f priv/sql/query/dev_list_brigades.sql

#   Run to generate the log directory
[group('  dev')]
@generate_log_directory:
    mkdir -p 'priv/log'

#   Clears the server's log file
[group('  dev')]
@clear_log_file:
    just generate_log_directory
    echo "" > {{ log_file_path }}

[group('  dev')]
@peek_log_file:
    bat priv/log/server.log
