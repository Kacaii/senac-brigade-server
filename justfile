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

# 󰏓  Builds the project for production
[group('  ship')]
[group('  gleam')]
build:
    gleam export erlang-shipment

#   Runs erlang-shipment entrypoint
[group('  ship')]
prod:
    ./build/erlang-shipment/entrypoint.sh run

# 󰜉  Rebuild an empty database
[group('  postgres')]
[group('  ship')]
@rebuild_empty:
    just clear_log_file
    psql senac_brigade -f priv/sql/drop.sql
    psql senac_brigade -f priv/sql/create/tables.sql
    psql senac_brigade -f priv/sql/create/triggers.sql
    psql senac_brigade -f priv/sql/create/functions.sql
    psql senac_brigade -f priv/sql/create/views.sql

# 󰜉  Rebuild the database with values in it
[group('  postgres')]
[group('  dev')]
@rebuild_full:
    just rebuild_empty

# 󰒋  Generate the first admin user, use this with the server RUNNING
[group('  dev')]
setup_admin:
    http POST :8000/admin/setup key="admin"

#   Login and generate users with different roles
[group('  admin')]
setup_roles:
    bash ./priv/dev_insert_users.sh

#   Runs a SELECT statement to query the user accounts
[group('  postgres')]
[group('  dev')]
[group('󰤏  query')]
list_user_accounts:
    psql senac_brigade -f priv/sql/query/dev_list_user_accounts.sql

#   Runs a SELECT statement to query the briagdes
[group('  postgres')]
[group('  dev')]
[group('󰤏  query')]
list_brigades:
    psql senac_brigade -f priv/sql/query/dev_list_brigades.sql

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
