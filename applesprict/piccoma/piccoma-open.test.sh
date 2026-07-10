#!/usr/bin/env bash
set -euo pipefail

script_path="${1:-applesprict/piccoma/piccoma-open.applescript}"
reminder_script_path="${2:-applesprict/piccoma/piccoma-reminder.applescript}"

assert_contains() {
	local needle="$1"
	local description="$2"

	if ! /usr/bin/grep -Fq "$needle" "$script_path"; then
		printf 'FAIL: %s\nMissing: %s\n' "$description" "$needle" >&2
		exit 1
	fi
}

assert_not_contains() {
	local needle="$1"
	local description="$2"

	if /usr/bin/grep -Fq "$needle" "$script_path"; then
		printf 'FAIL: %s\nForbidden: %s\n' "$description" "$needle" >&2
		exit 1
	fi
}

assert_order() {
	local first="$1"
	local second="$2"
	local description="$3"
	local first_line
	local second_line

	first_line=$(/usr/bin/grep -Fn "$first" "$script_path" | /usr/bin/head -n 1 | /usr/bin/cut -d: -f1 || true)
	second_line=$(/usr/bin/grep -Fn "$second" "$script_path" | /usr/bin/head -n 1 | /usr/bin/cut -d: -f1 || true)

	if [[ -z "$first_line" || -z "$second_line" || "$first_line" -ge "$second_line" ]]; then
		printf 'FAIL: %s\nExpected "%s" before "%s".\n' "$description" "$first" "$second" >&2
		exit 1
	fi
}

assert_contains 'my assertBookshelfOpened(historyTab)' 'bookshelf availability is checked before link extraction'
assert_contains 'on assertBookshelfOpened(theTab)' 'bookshelf availability check handler exists'
assert_contains 'display alert "本棚を開けませんでした"' 'fatal bookshelf failure alert is shown'
assert_contains 'ログイン状態を確認してから再実行してください。' 'alert explains login/session recovery'
assert_contains 'error number -128' 'bookshelf failure terminates abnormally'
assert_order 'my assertBookshelfOpened(historyTab)' 'set targetLinks to (execute historyTab javascript "' 'bookshelf check runs before target link extraction'
assert_contains 'on waitForBookshelfLoaded(theTab)' 'bookshelf load polling handler exists'
assert_contains 'my waitForBookshelfLoaded(historyTab)' 'bookshelf load is polled after navigation'
assert_order 'my waitForBookshelfLoaded(historyTab)' 'my assertBookshelfOpened(historyTab)' 'load polling runs before bookshelf availability check'
assert_not_contains 'delay 3' 'fixed page-load delay is replaced by polling'
assert_not_contains 'delay 1 ' 'per-tab fixed delay is removed'

compiled_script=$(/usr/bin/mktemp -t piccoma-open-test)
cleanup() {
	/bin/rm -f "$compiled_script"
}
trap cleanup EXIT

for target in "$script_path" "$reminder_script_path"; do
	if ! compile_output=$(osacompile -o "$compiled_script" "$target" 2>&1); then
		printf 'FAIL: %s does not compile.\n%s\n' "$target" "$compile_output" >&2
		exit 1
	fi
done

printf 'PASS: piccoma-open bookshelf failure handling is present.\n'
