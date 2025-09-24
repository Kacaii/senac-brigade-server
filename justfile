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

[group('  ship')]
prod:
    ./build/erlang-shipment/entrypoint.sh run

#   Insert basic values into the category table
[group('  postgres')]
[group('  insert')]
[group('  dev')]
@insert_categories:
    psql  senac_brigade -f priv/sql/insert/dev_insert_occurrence_categories.sql
    echo '  {{ MAGENTA }}OCCURRENCE TABLE{{ NORMAL }} filled successfully'

# 󰜉  Rebuild an empty database
[group('  postgres')]
[group('  ship')]
@rebuild_empty:
    @psql senac_brigade -f priv/sql/create/tables.sql
    echo '󱏀  {{ MAGENTA }}TABLES{{ NORMAL }} created successfully'
    @psql senac_brigade -f priv/sql/create/functions.sql
    echo '󰊕  {{ MAGENTA }}FUNCTIONS{{ NORMAL }} created successfully'
    echo '󰪩  {{ BLUE }}DATABASE{{ NORMAL }} rebuilt successfully with {{ YELLOW }}empty{{ NORMAL }} tables'

# 󰜉  Rebuild the database with values in it
[group('  postgres')]
[group('  dev')]
@rebuild_full:
    just rebuild_empty
    just insert_categories
    echo '󰪩  {{ BLUE }}DATABASE{{ NORMAL }} is {{ GREEN }}ready{{ NORMAL }} to use'

#   Runs a SELECT statement to query the user accounts
[group('  postgres')]
[group('  dev')]
[group('󰤏  query')]
list_user_accounts:
    psql senac_brigade -f priv/sql/query/dev_list_user_accounts.sql

#   Runs a SELECT statement to query the occurrence categories
[group('  postgres')]
[group('  dev')]
[group('󰤏  query')]
list_occurrence_categories:
    psql senac_brigade -f priv/sql/query/dev_list_categories.sql

#   Runs a SELECT statement to query the briagdes
[group('  postgres')]
[group('  dev')]
[group('󰤏  query')]
list_brigades:
    psql senac_brigade -f priv/sql/query/dev_list_brigades.sql
