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

assert_contains 'on waitForBookshelfLoaded(theTab)' 'bookshelf load polling handler exists'
assert_contains 'my waitForBookshelfLoaded(historyTab)' 'bookshelf load is polled after navigation'
assert_order 'my waitForBookshelfLoaded(historyTab)' 'set targetLinks to (execute historyTab javascript "' 'load polling runs before target link extraction'
assert_contains "return 'login_required'" 'login detection is merged into the polling javascript'
assert_contains "return 'not_bookshelf'" 'URL validation is merged into the polling javascript'
assert_contains "return 'no_target'" 'rendered-but-no-badge state short-circuits the polling wait'
assert_contains 'a[href*=\"/web/product/\"]' 'product links are used to detect a rendered bookshelf list'
assert_not_contains 'on assertBookshelfOpened' 'separate post-polling assertion round trip is removed'
assert_contains 'display alert "本棚を開けませんでした"' 'fatal bookshelf failure alert is shown'
assert_contains 'ログイン状態を確認してから再実行してください。' 'alert explains login/session recovery'
assert_contains 'error number -128' 'bookshelf failure terminates abnormally'
assert_not_contains 'delay 3' 'fixed page-load delay is replaced by polling'
assert_not_contains 'delay 1 ' 'per-tab fixed delay is removed'
assert_contains 'delay 0.2' 'early polling uses a short interval to catch fast loads'
assert_contains 'delay 0.5' 'later polling backs off to the longer interval'
assert_order 'delay 0.2' 'delay 0.5' 'short interval comes before the backoff interval'

# --reminder 統合モード: 開いた作品タブへ続けてリマインダー登録まで実行する
assert_contains 'arg is "--reminder" or arg is "-r"' 'reminder integration flag is parsed'
assert_contains '/piccoma-reminder.applescript' 'reminder script source is loaded from the script folder'
assert_contains 'run script reminderSource with parameters {scriptFolder}' 'integrated mode chains into piccoma-reminder with the script folder'
assert_order 'make new tab with properties {URL:linkURL}' 'run script reminderSource' 'tabs are opened before the reminder chain runs'
assert_contains 'if runReminder and bookshelfState is "ready"' 'reminder chain runs only when target tabs were opened'
assert_contains 'if showAlert and not reminderExecuted' 'open alert is suppressed when the reminder chain shows its own alert'

# --count の上限で誤指定によるタブの大量オープンを防ぐ
assert_contains 'set maxPageCount to 20' 'page count upper bound constant exists'
assert_contains 'pageCount > maxPageCount' 'page count upper bound is enforced'

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

printf 'PASS: piccoma-open bookshelf handling is present.\n'
