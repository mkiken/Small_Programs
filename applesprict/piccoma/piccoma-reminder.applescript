-- ピッコマの漫画詳細ページをすべてのタブから探し、タイトルと「¥0+」「爆読み¥0」の期限をリストに格納し、後でリマインダー「漫画」に追加する
-- Chromeなどからサービスで呼んだり、osascriptコマンドで呼んだりとサービス経由だととても重いので、automatorからアプリケーションとして起動するとよい

set startTime to (current date)

set noticeTextList to {}
set productTitleList to {}
set productTypeList to {}
set alertMessages to {}
set bingeFreePrefix to "【爆読み¥0】"

tell application "Google Chrome"
	activate
	set theWindow to front window
	set theTabs to every tab of theWindow
	set tabCount to count of theTabs

	repeat with i from 1 to tabCount
		set theTab to item i of theTabs
		set theURL to URL of theTab
		if theURL contains "https://piccoma.com/web/product" then
			-- 作品概要エリアのバッジから対象種別を判定
			set productType to (execute theTab javascript "
				(function() {
					const summary = document.querySelector('.PCM-l_productSummary1, .PCM-productSummary1');
					const noticeText = Array.from(document.querySelectorAll('.PCM-productNoticeList_notice, .PCM-productNoticeList_campaign'))
						.map((node) => node.textContent.trim())
						.join(' ');
					if (summary && summary.querySelector('.PCOM-prdList_badge_bingefree')) return 'bingefree';
					if (summary && summary.querySelector('.PCOM-prdList_badge_freeplus')) return 'freeplus';
					if (noticeText.includes('爆読み¥0') || noticeText.includes('爆読み￥0')) return 'bingefree';
					if (noticeText.includes('「¥0+」は') || noticeText.includes('¥0+') || noticeText.includes('￥0+')) return 'freeplus';
					return '';
				})()
			") as text

			-- 対象種別に応じた期日テキストを取得
			set noticeText to (execute theTab javascript "
				(function() {
					const productType = '" & productType & "';
					const nodes = document.querySelectorAll('.PCM-productNoticeList_notice, .PCM-productNoticeList_campaign');
					let fallback = '';
					for (let i = 0; i < nodes.length; i++) {
						const txt = nodes[i].textContent.trim();
						if (productType === 'bingefree') {
							if (txt.includes('爆読み')) return txt;
						} else {
							if (txt.includes('「¥0+」は')) return txt;
							if (!fallback && (txt.includes('¥0+') || txt.includes('￥0+'))) fallback = txt;
						}
					}
					return fallback;
				})()
			") as text
			-- タイトルを取得
			set productTitle to (execute theTab javascript "document.querySelector('.PCM-productTitle').textContent.trim()") as text

			-- 配列に追加
			set end of noticeTextList to noticeText
			set end of productTitleList to productTitle
			set end of productTypeList to productType
		end if
	end repeat
end tell

-- 配列を使ってリマインダー作成
set skippedList to {}
set scriptFolder to (do shell script "dirname " & quoted form of POSIX path of (path to me))

repeat with i from 1 to (count of noticeTextList)
	set noticeText to item i of noticeTextList
	set productTitle to item i of productTitleList
	set productType to item i of productTypeList

	if productType is "freeplus" or productType is "bingefree" then
		-- Base64エンコードして安全にシェルへ渡す
		set encodedText to do shell script "printf '%s' " & quoted form of noticeText & " | base64"

		set dateString to do shell script scriptFolder & "/extract-date.sh " & quoted form of encodedText
		set hasDueDate to false
		if dateString is not "" and dateString does not contain "¥0" and dateString does not contain "￥0" then
			set hasDueDate to true
			set dueDate to date dateString
		end if

		if productType is "freeplus" and hasDueDate is false then
			set end of skippedList to (productTitle & " (" & noticeText & ")")
		else
			set reminderName to productTitle
			set alternateReminderName to bingeFreePrefix & productTitle
			if productType is "bingefree" then
				set reminderName to bingeFreePrefix & productTitle
				set alternateReminderName to productTitle
			end if

			-- 同じ作品の既存リマインダーを取得
			set existingReminder to missing value
			tell application "Reminders"
				tell list "漫画"
					set foundReminders to (get reminders whose name is reminderName and completed is false)
					if (count of foundReminders) > 0 then
						set existingReminder to item 1 of foundReminders
					else
						set foundReminders to (get reminders whose name is alternateReminderName and completed is false)
						if (count of foundReminders) > 0 then
							set existingReminder to item 1 of foundReminders
						end if
					end if

					if existingReminder is not missing value then
						set reminderChanged to false
						if name of existingReminder is not reminderName then
							set name of existingReminder to reminderName
							set reminderChanged to true
						end if

						if hasDueDate then
							set currentDueDate to due date of existingReminder
							if currentDueDate is missing value or currentDueDate is not dueDate then
								set due date of existingReminder to dueDate
								set reminderChanged to true
							end if

							if reminderChanged then
								set end of alertMessages to (reminderName & " (" & dueDate & ")")
							end if
						else
							if due date of existingReminder is not missing value then
								set due date of existingReminder to missing value
								set reminderChanged to true
							end if

							if reminderChanged then
								set end of alertMessages to (reminderName & " (期限なし)")
							end if
						end if
					else
						if hasDueDate then
							make new reminder with properties {name:reminderName, due date:dueDate}
							set end of alertMessages to (reminderName & " (" & dueDate & ")")
						else
							make new reminder with properties {name:reminderName}
							set end of alertMessages to (reminderName & " (期限なし)")
						end if
					end if
				end tell
			end tell
		end if
	end if
end repeat

set endTime to (current date)
set elapsedSeconds to (endTime - startTime) as integer

set alertText to ""

if (count of alertMessages) > 0 then
	set alertText to "登録/更新:\n" & (my joinList(alertMessages, "\n"))
end if

if (count of skippedList) > 0 then
	if alertText is not "" then set alertText to alertText & "\n\n"
	set alertText to alertText & "⚠️ 日付抽出失敗（スキップ）:\n" & (my joinList(skippedList, "\n"))
end if

if alertText is "" then
	set alertText to "新規登録・更新されたリマインダーはありませんでした。"
end if

set alertText to alertText & "\n\n実行時間: " & elapsedSeconds & "秒"
display alert "リマインダー処理完了" message alertText

on joinList(theList, delimiter)
	set {oldDelims, AppleScript's text item delimiters} to {AppleScript's text item delimiters, delimiter}
	set joined to theList as text
	set AppleScript's text item delimiters to oldDelims
	return joined
end joinList
