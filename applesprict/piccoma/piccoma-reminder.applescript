-- ピッコマの漫画詳細ページをすべてのタブから探し、タイトルと「¥0+」「爆読み¥0」の期限をリストに格納し、後でリマインダー「漫画」に追加する
-- Chromeなどからサービスで呼んだり、osascriptコマンドで呼んだりとサービス経由だととても重いので、automatorからアプリケーションとして起動するとよい
-- piccoma-openの--reminder（統合モード）からはrun script経由で呼ばれ、第1引数にスクリプトフォルダが渡る

-- 期限切れの既存リマインダーを実行時に自動で完了済みへ移すかどうか
property autoCompleteExpired : true

on run argv
	set startTime to (current date)

	set noticeTextList to {}
	set productTitleList to {}
	set productTypeList to {}
	set dueDateStringList to {}
	set alertMessages to {}
	set loadFailedList to {}
	set completedExpiredList to {}
	set bingeFreePrefix to "【爆読み¥0】"

	-- run script経由ではpath to meが呼び出し元を指すため、統合モードはスクリプトフォルダを引数で受け取る
	set scriptFolder to ""
	try
		if (count of argv) > 0 then set scriptFolder to (item 1 of argv) as text
	end try
	if scriptFolder is "" then set scriptFolder to (do shell script "dirname " & quoted form of POSIX path of (path to me))
	-- 期日抽出ロジックはページ内JavaScriptへ注入して実行する（作品ごとのシェル起動をなくすため）
	set extractDateJs to read POSIX file (scriptFolder & "/extract-date.js") as «class utf8»

	set theWindow to missing value
	set urlList to {}
	tell application "Google Chrome"
		if (count of windows) > 0 then
			activate
			set theWindow to front window
			-- Apple Eventの往復を減らすためタブURLは一括取得する
			set urlList to URL of every tab of theWindow
		end if
	end tell
	if theWindow is missing value then
		display alert "Chromeのウィンドウがありません" message "作品ページを開いたウィンドウを前面にしてから再実行してください。" as critical
		error number -128
	end if

	set tabIndex to 0
	repeat with theURL in urlList
		set tabIndex to tabIndex + 1
		if (theURL as text) contains "https://piccoma.com/web/product" then
			set productInfo to my fetchProductInfo(theWindow, tabIndex, extractDateJs)
			if productInfo is "LOADING" then
				set end of loadFailedList to (theURL as text)
			else
				set infoItems to my splitText(productInfo, tab)
				if (count of infoItems) is 4 then
					set end of productTypeList to item 1 of infoItems
					set end of noticeTextList to item 2 of infoItems
					set end of productTitleList to item 3 of infoItems
					set end of dueDateStringList to item 4 of infoItems
				end if
			end if
		end if
	end repeat

	-- 対象作品が1件もなければ、この後のRemindersアクセス（遅いwhoseクエリ）を丸ごと省く
	set hasTargetProduct to false
	repeat with candidateType in productTypeList
		if (contents of candidateType) is "freeplus" or (contents of candidateType) is "bingefree" then
			set hasTargetProduct to true
			exit repeat
		end if
	end repeat

	-- 「漫画」リストの未完了リマインダーの名前・期限・idをpropertiesで一括取得してキャッシュする（遅いwhoseクエリはここの1回だけ）
	set cachedNames to {}
	set cachedIds to {}
	set cachedDueDates to {}
	if hasTargetProduct then
		set fetchFailed to false
		tell application "Reminders"
			try
				tell list "漫画"
					set cachedProps to properties of (reminders whose completed is false)
				end tell
			on error
				set fetchFailed to true
			end try
			if not fetchFailed then
				repeat with cachedRec in cachedProps
					set end of cachedNames to name of cachedRec
					set end of cachedIds to id of cachedRec
					set end of cachedDueDates to due date of cachedRec
				end repeat
			end if
		end tell
		if fetchFailed then
			display alert "リマインダーリスト「漫画」にアクセスできません" message "Remindersに「漫画」リストが存在するか、アクセス許可を確認してから再実行してください。" as critical
			error number -128
		end if
	end if

	-- 配列を使ってリマインダー作成
	set skippedList to {}
	set touchedIndices to {}

	repeat with i from 1 to (count of noticeTextList)
		set noticeText to item i of noticeTextList
		set productTitle to item i of productTitleList
		set productType to item i of productTypeList
		set dateString to item i of dueDateStringList

		if productType is "freeplus" or productType is "bingefree" then
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

				if foundIndex > 0 then
					-- 今回対象として現れた作品は期限切れ掃除の対象外にする
					set end of touchedIndices to foundIndex

					-- 変更の要否はキャッシュ上で判定し、Apple Eventは実際に書き込むときだけ送る
					set needsRename to ((item foundIndex of cachedNames) is not reminderName)
					set cachedDueDate to item foundIndex of cachedDueDates
					if hasDueDate then
						set needsDueDateUpdate to (cachedDueDate is missing value) or (cachedDueDate is not dueDate)
					else
						set needsDueDateUpdate to (cachedDueDate is not missing value)
					end if

					if needsRename or needsDueDateUpdate then
						tell application "Reminders"
							tell list "漫画"
								set existingReminder to reminder id (item foundIndex of cachedIds)
								if needsRename then set name of existingReminder to reminderName
								if needsDueDateUpdate then
									if hasDueDate then
										set due date of existingReminder to dueDate
									else
										set due date of existingReminder to missing value
									end if
								end if
							end tell
						end tell

						set item foundIndex of cachedNames to reminderName
						if hasDueDate then
							set item foundIndex of cachedDueDates to dueDate
							set end of alertMessages to (reminderName & " (" & dueDate & ")")
						else
							set item foundIndex of cachedDueDates to missing value
							set end of alertMessages to (reminderName & " (期限なし)")
						end if
					end if
				else
					tell application "Reminders"
						tell list "漫画"
							if hasDueDate then
								set newReminder to make new reminder with properties {name:reminderName, due date:dueDate}
							else
								set newReminder to make new reminder with properties {name:reminderName}
							end if
							set newReminderId to id of newReminder
						end tell
					end tell

					if hasDueDate then
						set end of alertMessages to (reminderName & " (" & dueDate & ")")
						set end of cachedDueDates to dueDate
					else
						set end of alertMessages to (reminderName & " (期限なし)")
						set end of cachedDueDates to missing value
					end if
					-- 同一実行内で同じ作品を重複作成しないようキャッシュへ追加する
					set end of cachedNames to reminderName
					set end of cachedIds to newReminderId
					set end of touchedIndices to (count of cachedNames)
				end if
			end if
		end if
	end repeat

	-- 期限切れの既存リマインダーを完了済みへ移す（追加のwhoseクエリを避けるため、キャッシュ取得済みの実行時だけ行う）
	if autoCompleteExpired and hasTargetProduct then
		set expiredIndexList to {}
		repeat with i from 1 to (count of cachedIds)
			if my indexOf(touchedIndices, i) is 0 then
				set cachedDueDate to item i of cachedDueDates
				if cachedDueDate is not missing value and cachedDueDate < startTime then
					set end of expiredIndexList to i
				end if
			end if
		end repeat
		if (count of expiredIndexList) > 0 then
			tell application "Reminders"
				tell list "漫画"
					repeat with expiredIndex in expiredIndexList
						set completed of (reminder id (item (contents of expiredIndex) of cachedIds)) to true
					end repeat
				end tell
			end tell
			repeat with expiredIndex in expiredIndexList
				set end of completedExpiredList to (item (contents of expiredIndex) of cachedNames)
			end repeat
		end if
	end if

	set endTime to (current date)
	set elapsedSeconds to (endTime - startTime) as integer

	set alertText to ""

	if (count of alertMessages) > 0 then
		set alertText to "登録/更新:\n" & (my joinList(alertMessages, "\n"))
	end if

	if (count of completedExpiredList) > 0 then
		if alertText is not "" then set alertText to alertText & "\n\n"
		set alertText to alertText & "完了(期限切れ):\n" & (my joinList(completedExpiredList, "\n"))
	end if

	if (count of skippedList) > 0 then
		if alertText is not "" then set alertText to alertText & "\n\n"
		set alertText to alertText & "⚠️ 日付抽出失敗（スキップ）:\n" & (my joinList(skippedList, "\n"))
	end if

	if (count of loadFailedList) > 0 then
		if alertText is not "" then set alertText to alertText & "\n\n"
		set alertText to alertText & "⚠️ 読み込みタイムアウト（スキップ）:\n" & (my joinList(loadFailedList, "\n"))
	end if

	if alertText is "" then
		set alertText to "新規登録・更新されたリマインダーはありませんでした。"
	end if

	set alertText to alertText & "\n\n実行時間: " & elapsedSeconds & "秒"
	display alert "リマインダー処理完了" message alertText
end run

-- ページ読み込み完了をポーリングで待ちながら、種別判定・期日テキスト・タイトル・期日抽出を1回のJavaScript実行でまとめて行う
-- タイムアウトまで描画されなければ "LOADING" を返す（0.2秒×5回→0.5秒間隔、最大約4秒）
on fetchProductInfo(theWindow, tabIndex, extractDateJs)
	set productInfo to "LOADING"
	repeat with attempt from 1 to 12
		set productInfo to "LOADING"
		try
			tell application "Google Chrome"
				set productInfo to (execute (tab tabIndex of theWindow) javascript "
					(function() {
						" & extractDateJs & "
						// レンダリング前のタブはマーカーを返し、AppleScript側のポーリングで再試行する
						const titleNode = document.querySelector('.PCM-productTitle');
						if (!titleNode) return 'LOADING';

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

						const title = titleNode.textContent.trim();

						const dueDateString = extractDueDate(noticeText, new Date());

						// タブ区切りで返すため、値中のタブは空白に潰す
						return [productType, noticeText, title, dueDateString].map((v) => v.replace(/\\t/g, ' ')).join('\\t');
					})()
				") as text
			end tell
		end try
		if productInfo is not "LOADING" then return productInfo
		-- 描画完了の直後を逃さないよう序盤は短い間隔で、以降は0.5秒間隔に戻す
		if attempt < 12 then
			if attempt ≤ 5 then
				delay 0.2
			else
				delay 0.5
			end if
		end if
	end repeat
	return productInfo
end fetchProductInfo

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

-- extract-date.js の出力 "YYYY/M/D HH:MM" をロケール非依存で date に変換する
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
