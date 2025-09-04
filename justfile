# Print recipes list
@default:
    just --list

#   Run the project
run:
    gleam run

# 󰙨  Run all unit tests
test:
    gleam test

#   Watch for file changes and run the project
watch_run:
    watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam --debounce 500ms --watch src/ -- "clear; gleam run"

#   Watch for file changes and run unit tests
watch_test:
    watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM --exts gleam --debounce 500ms --watch src/ -- "clear; gleam run"
