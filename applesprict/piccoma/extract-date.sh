#!/bin/bash
# stdin: 期限を含む通知テキスト
# 出力: "YYYY/M/D HH:MM" 形式の期限（抽出できなければ空文字）
# EXTRACT_DATE_NOW: テスト用に「現在時刻」を epoch 秒で注入できる。未設定なら現在時刻。
text=$(cat)
now="${EXTRACT_DATE_NOW:-$(date +%s)}"

# パターン1: YYYY/M/D(曜日)HH:MM または YYYY/M/D HH:MM
match=$(printf '%s' "$text" | grep -oE '[0-9]{4}/[0-9]{1,2}/[0-9]{1,2}[^0-9]*[0-9]{2}:[0-9]{2}' | head -n 1)
if [[ -n "$match" ]]; then
    printf '%s' "$match" | sed -E 's/^([0-9]{4}\/[0-9]{1,2}\/[0-9]{1,2})[^0-9]*([0-9]{2}:[0-9]{2})$/\1 \2/'
    exit 0
fi

# パターン1b: 時刻なしの YYYY/M/D → その日いっぱいが期限とみなし 23:59 を補完
match=$(printf '%s' "$text" | grep -oE '[0-9]{4}/[0-9]{1,2}/[0-9]{1,2}' | head -n 1)
if [[ -n "$match" ]]; then
    printf '%s 23:59\n' "$match"
    exit 0
fi

# パターン2: M/D(曜日)HH:MM（年なし → 年を補完）
match=$(printf '%s' "$text" | grep -oE '[0-9]{1,2}/[0-9]{1,2}\([^)]+\)[0-9]{2}:[0-9]{2}' | head -n 1)
if [[ -n "$match" ]]; then
    md_time=$(printf '%s' "$match" | sed -E 's/^([0-9]{1,2}\/[0-9]{1,2})\([^)]+\)([0-9]{2}:[0-9]{2})$/\1 \2/')
    year=$(date -r "$now" +%Y)
    candidate="$year/$md_time"
    # 現在年で解釈して180日以上過去なら年またぎ（12月に見た1月期限など）とみなし翌年に補正する
    epoch=$(date -j -f '%Y/%m/%d %H:%M' "$candidate" +%s 2>/dev/null || true)
    if [[ -n "$epoch" ]] && ((epoch < now - 180 * 86400)); then
        candidate="$((year + 1))/$md_time"
    fi
    printf '%s\n' "$candidate"
    exit 0
fi

# どのパターンにもマッチしない場合は空文字
echo ''
