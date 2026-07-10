#!/usr/bin/env bash
set -euo pipefail

script_path="${1:-applesprict/piccoma/piccoma-reminder.applescript}"

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

# 期日抽出はシェルではなくページ内JavaScriptで行う
assert_contains 'read POSIX file (scriptFolder & "/extract-date.js")' 'date extraction library is loaded from extract-date.js'
assert_contains '" & extractDateJs & "' 'date extraction library is injected into the page javascript'
assert_contains 'extractDueDate(noticeText, new Date())' 'due date is extracted inside the page javascript'
assert_not_contains 'extract-date.sh' 'per-product shell invocation is removed'

# 遅いwhoseクエリは1回だけ、名前・期限・idはpropertiesで一括取得する
assert_contains 'properties of (reminders whose completed is false)' 'incomplete reminders are bulk-fetched with properties'
whose_count=$(/usr/bin/grep -Fc 'whose completed is false' "$script_path")
if [[ "$whose_count" -ne 1 ]]; then
	printf 'FAIL: expected exactly 1 whose query, found %s.\n' "$whose_count" >&2
	exit 1
fi

# 書き込みが必要なときだけ reminder id で参照し、判定はキャッシュ上で行う
assert_contains 'reminder id (item foundIndex of cachedIds)' 'updates resolve the reminder by cached id'
assert_contains 'item foundIndex of cachedDueDates' 'due date comparison uses the cached value'
assert_not_contains 'due date of existingReminder is not missing value' 'per-product due date read is removed'

printf 'PASS: piccoma-reminder consolidation is present.\n'
