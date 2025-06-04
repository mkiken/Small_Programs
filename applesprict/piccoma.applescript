-- ピッコマの漫画詳細ページをすべてのタブから探し、タイトルと「¥0+」の期限をリストに格納し、後でリマインダー「漫画」に追加する

set startTime to (current date)

set noticeTextList to {}
set productTitleList to {}
set alertMessages to {}

tell application "Google Chrome"
	activate
	set theWindow to front window
	set theTabs to every tab of theWindow
	set tabCount to count of theTabs

	repeat with i from 1 to tabCount
		set theTab to item i of theTabs
		set theURL to URL of theTab
		if theURL contains "https://piccoma.com/web/product" then
			-- 「¥0+」の期日を取得
			set noticeText to (execute theTab javascript "
				(function() {
					const nodes = document.querySelectorAll('.PCM-productNoticeList_notice');
					for (let i = 0; i < nodes.length; i++) {
						const txt = nodes[i].textContent.trim();
						if (txt.includes('¥0+')) return txt;
					}
					return '';
				})()
			") as text
			-- タイトルを取得
			set productTitle to (execute theTab javascript "document.querySelector('.PCM-productTitle').textContent.trim()") as text

			-- 配列に追加
			set end of noticeTextList to noticeText
			set end of productTitleList to productTitle
		end if
	end repeat
end tell

-- 配列を使ってリマインダー作成
repeat with i from 1 to (count of noticeTextList)
	set noticeText to item i of noticeTextList
	set productTitle to item i of productTitleList

	-- 日付部分のみ抽出
	set dateString to do shell script "echo " & quoted form of noticeText & " | sed -E 's/.*([0-9]{4}\\/[0-9]{1,2}\\/[0-9]{1,2}).*([0-9]{2}:[0-9]{2})/\\1 \\2/'"

	if dateString is not "" then
		set dueDate to date dateString

		-- ここでproductTitleで1件だけリマインダーを取得
		set existingReminder to missing value
		tell application "Reminders"
			tell list "漫画"
				set foundReminders to (get reminders whose name is productTitle and completed is false)
				if (count of foundReminders) > 0 then
					set existingReminder to item 1 of foundReminders
				end if

				if existingReminder is not missing value then
					if due date of existingReminder is not dueDate then
						set due date of existingReminder to dueDate
						set end of alertMessages to (productTitle & " (" & dueDate & ")")
					end if
				else
					make new reminder with properties {name:productTitle, due date:dueDate}
					set end of alertMessages to (productTitle & " (" & dueDate & ")")
				end if
			end tell
		end tell
	end if
end repeat

set endTime to (current date)
set elapsedSeconds to (endTime - startTime) as integer

if (count of alertMessages) > 0 then
	set alertText to "リマインダー登録完了:\n" & (my joinList(alertMessages, "\n")) & "\n\n実行時間: " & elapsedSeconds & "秒"
	display alert "リマインダー登録完了" message alertText
else
	display alert "リマインダー登録完了" message "新規登録・更新されたリマインダーはありませんでした。\n\n実行時間: " & elapsedSeconds & "秒"
end if

on joinList(theList, delimiter)
	set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, delimiter}
	set joined to theList as text
	set AppleScript's text item delimiters to oldDelims
	return joined
end joinList