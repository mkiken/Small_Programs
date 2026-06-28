#!/usr/bin/env bash
set -euo pipefail

script_path="${1:-applesprict/piccoma/piccoma-open.applescript}"

assert_contains() {
	local needle="$1"
	local description="$2"

	if ! /usr/bin/grep -Fq "$needle" "$script_path"; then
		printf 'FAIL: %s\nMissing: %s\n' "$description" "$needle" >&2
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

compiled_script=$(/usr/bin/mktemp -t piccoma-open-test)
cleanup() {
	/bin/rm -f "$compiled_script"
}
trap cleanup EXIT

if ! compile_output=$(osacompile -o "$compiled_script" "$script_path" 2>&1); then
	printf 'FAIL: piccoma-open.applescript does not compile.\n%s\n' "$compile_output" >&2
	exit 1
fi

printf 'PASS: piccoma-open bookshelf failure handling is present.\n'
