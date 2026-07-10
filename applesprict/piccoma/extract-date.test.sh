#!/usr/bin/env bash
set -euo pipefail

script_path="${1:-applesprict/piccoma/extract-date.sh}"

# 年またぎ判定を決定的にするため、タイムゾーンを固定して epoch を組み立てる
export TZ=Asia/Tokyo

epoch() {
	/bin/date -j -f '%Y-%m-%d %H:%M' "$1" +%s
}

failures=0

# 各ケース: 説明 / 入力テキスト / EXTRACT_DATE_NOW（空なら未注入） / 期待出力
run_case() {
	local description="$1"
	local input="$2"
	local now="$3"
	local expected="$4"
	local actual

	if [[ -n "$now" ]]; then
		actual=$(printf '%s' "$input" | EXTRACT_DATE_NOW="$now" /bin/bash "$script_path")
	else
		actual=$(printf '%s' "$input" | /bin/bash "$script_path")
	fi

	if [[ "$actual" != "$expected" ]]; then
		printf 'FAIL: %s\n  input:    %s\n  expected: [%s]\n  actual:   [%s]\n' "$description" "$input" "$expected" "$actual" >&2
		failures=$((failures + 1))
	fi
}

run_case '年あり: YYYY/M/D(曜日)HH:MM' \
	'「¥0+」は2026/7/15(水)23:59まで毎日1話¥0+で読めます' '' '2026/7/15 23:59'

run_case '年あり: YYYY/MM/DD HH:MM（空白区切り）' \
	'2026/07/05 08:00から提供予定' '' '2026/07/05 08:00'

run_case '年なし: 未来日付は現在年で補完' \
	'爆読み¥0は7/15(水)23:59まで' "$(epoch '2026-07-11 12:00')" '2026/7/15 23:59'

run_case '年なし: 年またぎ（12月に見た1月期限）は翌年に補正' \
	'爆読み¥0は1/5(月)23:59まで' "$(epoch '2026-12-20 12:00')" '2027/1/5 23:59'

run_case '年なし: 直近の過去（前日期限切れ）は現在年のまま' \
	'「¥0+」は7/10(金)23:59まで' "$(epoch '2026-07-11 12:00')" '2026/7/10 23:59'

run_case '年なし境界: 180日以内の過去は現在年のまま' \
	'「¥0+」は1/25(日)00:00まで' "$(epoch '2026-07-11 12:00')" '2026/1/25 00:00'

run_case '年なし境界: 180日超の過去は翌年に補正' \
	'「¥0+」は1/1(木)00:00まで' "$(epoch '2026-07-11 12:00')" '2027/1/1 00:00'

run_case '年なし: 2桁の月が欠けずに抽出される' \
	'爆読み¥0は12/25(金)23:59まで' "$(epoch '2026-12-01 00:00')" '2026/12/25 23:59'

run_case '時刻なし: 23:59 を補完' \
	'「¥0+」は2026/7/15まで' '' '2026/7/15 23:59'

run_case '日付なし: 空文字' \
	'¥0+対象作品です' '' ''

run_case '空入力: 空文字' \
	'' '' ''

if ((failures > 0)); then
	printf 'FAIL: %d case(s) failed.\n' "$failures" >&2
	exit 1
fi

printf 'PASS: extract-date.sh all cases passed.\n'
