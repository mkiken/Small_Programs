#!/bin/bash
# 引数: Base64エンコードされたテキスト
encoded="$1"
text=$(printf '%s' "$encoded" | base64 -d)

# パターン1: YYYY/MM/DD(曜日)HH:MM または YYYY/MM/DD HH:MM
if printf '%s' "$text" | grep -qE '[0-9]{4}/[0-9]{1,2}/[0-9]{1,2}'; then
    printf '%s' "$text" | sed -E 's/.*([0-9]{4})\/([0-9]{1,2})\/([0-9]{1,2})[^0-9]*([0-9]{2}:[0-9]{2}).*/\1\/\2\/\3 \4/'
    exit 0
fi

# パターン2: M/D(曜日)HH:MM（年なし → 現在年を補完）
if printf '%s' "$text" | grep -qE '[0-9]{1,2}/[0-9]{1,2}\([^)]+\)[0-9]{2}:[0-9]{2}'; then
    year=$(date +%Y)
    printf '%s' "$text" | sed -E 's/.*([0-9]{1,2})\/([0-9]{1,2})\([^)]+\)([0-9]{2}:[0-9]{2}).*/YEAR\/\1\/\2 \3/' | sed "s/YEAR/$year/"
    exit 0
fi

# どちらにもマッチしない場合は空文字
echo ''
