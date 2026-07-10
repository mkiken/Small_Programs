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
	-- Apple Eventの往復を減らすためタブURLは一括取得する
	set urlList to URL of every tab of theWindow

	repeat with i from 1 to (count of urlList)
		set theURL to item i of urlList
		if theURL contains "https://piccoma.com/web/product" then
			-- 種別判定・期日テキスト・タイトルを1回のJavaScript実行でまとめて取得する
			set productInfo to (execute (tab i of theWindow) javascript "
				(function() {
					const summary = document.querySelector('.PCM-l_productSummary1, .PCM-productSummary1');
					const noticeNodes = Array.from(document.querySelectorAll('.PCM-productNoticeList_notice, .PCM-productNoticeList_campaign'));
					const noticeAll = noticeNodes.map((node) => node.textContent.trim()).join(' ');

					// 作品概要エリアのバッジから対象種別を判定
					let productType = '';
					if (summary && summary.querySelector('.PCOM-prdList_badge_bingefree')) productType = 'bingefree';
					else if (summary && summary.querySelector('.PCOM-prdList_badge_freeplus')) productType = 'freeplus';
					else if (noticeAll.includes('爆読み¥0') || noticeAll.includes('爆読み￥0')) productType = 'bingefree';
					else if (noticeAll.includes('「¥0+」は') || noticeAll.includes('¥0+') || noticeAll.includes('￥0+')) productType = 'freeplus';

					// 対象種別に応じた期日テキストを取得
					let noticeText = '';
					let fallback = '';
					for (const node of noticeNodes) {
						const txt = node.textContent.trim();
						if (productType === 'bingefree') {
							if (txt.includes('爆読み')) { noticeText = txt; break; }
						} else {
							if (txt.includes('「¥0+」は')) { noticeText = txt; break; }
							if (!fallback && (txt.includes('¥0+') || txt.includes('￥0+'))) fallback = txt;
						}
					}
					if (!noticeText) noticeText = fallback;

					const titleNode = document.querySelector('.PCM-productTitle');
					const title = titleNode ? titleNode.textContent.trim() : '';

					// タブ区切りで返すため、値中のタブは空白に潰す
					return [productType, noticeText, title].map((v) => v.replace(/\\t/g, ' ')).join('\\t');
				})()
			") as text

			set infoItems to my splitText(productInfo, tab)
			if (count of infoItems) is 3 then
				set end of productTypeList to item 1 of infoItems
				set end of noticeTextList to item 2 of infoItems
				set end of productTitleList to item 3 of infoItems
			end if
		end if
	end repeat
end tell

-- 「漫画」リストの未完了リマインダーを一括取得してキャッシュする（遅いwhoseクエリはここだけ）
tell application "Reminders"
	tell list "漫画"
		set cachedReminders to (get reminders whose completed is false)
		set cachedNames to (get name of reminders whose completed is false)
	end tell
end tell

-- 配列を使ってリマインダー作成
set skippedList to {}
set scriptFolder to (do shell script "dirname " & quoted form of POSIX path of (path to me))
set extractDateScript to quoted form of (scriptFolder & "/extract-date.sh")

repeat with i from 1 to (count of noticeTextList)
	set noticeText to item i of noticeTextList
	set productTitle to item i of productTitleList
	set productType to item i of productTypeList

	if productType is "freeplus" or productType is "bingefree" then
		-- quoted form で安全にエスケープし、stdin経由で日付抽出スクリプトへ渡す
		set dateString to do shell script "printf '%s' " & quoted form of noticeText & " | " & extractDateScript

		set hasDueDate to false
		if dateString is not "" then
			try
				set dueDate to my makeDateFromString(dateString)
				set hasDueDate to true
			end try
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

			-- 同じ作品の既存リマインダーをキャッシュから探す
			set foundIndex to my indexOf(cachedNames, reminderName)
			if foundIndex is 0 then set foundIndex to my indexOf(cachedNames, alternateReminderName)

			tell application "Reminders"
				tell list "漫画"
					if foundIndex > 0 then
						set existingReminder to item foundIndex of cachedReminders
						set reminderChanged to false
						if item foundIndex of cachedNames is not reminderName then
							set name of existingReminder to reminderName
							set item foundIndex of cachedNames to reminderName
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
							set newReminder to make new reminder with properties {name:reminderName, due date:dueDate}
							set end of alertMessages to (reminderName & " (" & dueDate & ")")
						else
							set newReminder to make new reminder with properties {name:reminderName}
							set end of alertMessages to (reminderName & " (期限なし)")
						end if
						-- 同一実行内で同じ作品を重複作成しないようキャッシュへ追加する
						set end of cachedReminders to newReminder
						set end of cachedNames to reminderName
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

on splitText(theText, delimiter)
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiter
	set splitItems to text items of theText
	set AppleScript's text item delimiters to oldDelims
	return splitItems
end splitText

on indexOf(theList, theValue)
	repeat with i from 1 to (count of theList)
		if item i of theList is theValue then return i
	end repeat
	return 0
end indexOf

-- extract-date.sh の出力 "YYYY/M/D HH:MM" をロケール非依存で date に変換する
on makeDateFromString(dateString)
	set parts to my splitText(dateString, " ")
	set ymd to my splitText(item 1 of parts, "/")
	set hm to my splitText(item 2 of parts, ":")
	return my makeDate((item 1 of ymd) as integer, (item 2 of ymd) as integer, (item 3 of ymd) as integer, (item 1 of hm) as integer, (item 2 of hm) as integer)
end makeDateFromString

on makeDate(y, m, d, hh, mm)
	set theDate to (current date)
	-- 月末日起因のオーバーフローを避けるため day を1に戻してから year→month→day→time の順に設定する
	set time of theDate to 0
	set day of theDate to 1
	set year of theDate to y
	set month of theDate to m
	set day of theDate to d
	set time of theDate to hh * hours + mm * minutes
	return theDate
end makeDate
