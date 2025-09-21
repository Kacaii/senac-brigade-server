login_route := ':8000/api/user/login'
signup_route := ':8000/api/user/signup'

alias s := squirrel
alias u := update

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

#   Generate code from SQL files
[group('  gleam')]
squirrel:
    gleam run -m squirrel

# 󰙨  Run all unit tests
[group('  gleam')]
test:
    gleam test

# 󰏓  Builds the project for production
[group('  gleam')]
build:
    gleam export erlang-shipment

#   Insert basic values into the category table
[group('  postgres')]
[group('  insert')]
@insert_categories:
    psql  senac_brigade -f priv/sql/insert/insert_occurrence_categories.sql
    echo '  {{ MAGENTA }}OCCURRENCE TABLE{{ NORMAL }} filled successfully'

# 󰜉  Rebuild an empty database
[group('  postgres')]
@rebuild_empty:
    @psql senac_brigade -f priv/sql/create/tables.sql
    echo '󱏀  {{ MAGENTA }}TABLES{{ NORMAL }} created successfully'
    @psql senac_brigade -f priv/sql/create/functions.sql
    echo '󰊕  {{ MAGENTA }}FUNCTIONS{{ NORMAL }} created successfully'
    echo '󰪩  {{ BLUE }}DATABASE{{ NORMAL }} rebuilt successfully with {{ YELLOW }}empty{{ NORMAL }} tables'

# 󰜉  Rebuild the database with values in it
[group('  postgres')]
@rebuild_full:
    just rebuild_empty
    just insert_categories
    echo '󰪩  {{ BLUE }}DATABASE{{ NORMAL }} is {{ GREEN }}ready{{ NORMAL }} to use'

#   Runs a SELECT statement to query the user accounts
[group('  postgres')]
[group('󰤏  query')]
list_user_accounts:
    psql senac_brigade -f priv/sql/query/list_user_accounts.sql | bat --language=markdown

#   Runs a SELECT statement to query the occurrence categories
[group('  postgres')]
[group('󰤏  query')]
list_occurrence_categories:
    psql senac_brigade -f priv/sql/query/list_categories.sql | bat --language=markdown

[group('  postgres')]
[group('󰤏  query')]
list_brigades:
    psql senac_brigade -f priv/sql/query/list_brigades.sql | bat --language=markdown

# 󱃜  Send a POST request to login
[group('󰯊  httpie')]
login registration password:
    http --form {{ login_route }} matricula={{ registration }} senha={{ password }}

# 󱃜  Send a POST request to signup
[group('󰯊  httpie')]
signup name registration phone email password confirm_password:
    http --form {{ signup_route }} nome="{{ name }}" matricula={{ registration }} telefone={{ phone }} email={{ email }} senha={{ password }} confirma_senha={{ confirm_password }}
