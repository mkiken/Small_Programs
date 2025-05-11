-- ピッコマの漫画詳細ページを読み込んでタイトルと「¥0+」の期限をリマインダー「漫画」に追加する

tell application "Google Chrome"
	activate
	set theTab to active tab of front window

	-- 「¥0+」の期日を取得
	set noticeText to (execute theTab javascript "document.querySelector('.PCM-productNoticeList_notice').textContent.trim()") as text
	-- タイトルを取得
	set productTitle to (execute theTab javascript "document.querySelector('.PCM-productTitle').textContent.trim()") as text

end tell

-- 日付部分のみ抽出
set dateString to do shell script "echo " & quoted form of noticeText & " | sed -E 's/.*([0-9]{4}\\/[0-9]{1,2}\\/[0-9]{1,2}).*([0-9]{2}:[0-9]{2})/\\1 \\2/'"

set dueDate to date dateString

-- リマインダー作成
tell application "Reminders"
	tell list "漫画" -- デフォルトリスト名（必要に応じて変更）
		make new reminder with properties {name:productTitle, due date:dueDate}
	end tell
end tell

display alert "リマインダー登録完了" message "リマインダー登録完了: " & productTitle & "(" & dueDate & ")"