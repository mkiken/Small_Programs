-- ピッコマの「¥0+」と「爆読み¥0」の漫画詳細ページをN件開く
-- Chromeなどからサービスで呼んだり、osascriptコマンドで呼んだりとサービス経由だととても重いので、automatorからアプリケーションとして起動するとよい

on run argv
	-- フラグ解析
	set showAlert to true
	set pageCount to 5 -- デフォルト値

	set i to 1
	repeat while i <= (count of argv)
		set arg to item i of argv
		if arg is "--silent" or arg is "-s" then
			set showAlert to false
		else if arg is "--count" or arg is "-c" then
			if i + 1 <= (count of argv) then
				try
					set pageCount to (item (i + 1) of argv as integer)
					if pageCount < 1 then
						display dialog "ページ数には1以上の数値を指定してください。" with icon stop with title "引数エラー"
						error number -128
					end if
					set i to i + 1
				on error
					display dialog "ページ数には数値を指定してください。" with icon stop with title "引数エラー"
					error number -128
				end try
			else
				display dialog "--countフラグにはページ数を指定してください。" with icon stop with title "引数エラー"
				error number -128
			end if
		end if
		set i to i + 1
	end repeat


	set startTime to (current date)

	tell application "Google Chrome"
		activate
		set theWindow to make new window

		-- お気に入りページを新規ウィンドウの最初のタブで開く
		tell theWindow
			set historyTab to active tab
			set URL of historyTab to "https://piccoma.com/web/bookshelf/bookmark"
			set bookshelfState to my waitForBookshelfLoaded(historyTab)

			if bookshelfState is not "ready" and bookshelfState is not "no_target" then
				display alert "本棚を開けませんでした" message "ログイン状態を確認してから再実行してください。" as critical
				error number -128
			end if

			-- 対象バッジを持つリンクを取得（対象作品なしが確定していればJavaScript実行ごと省く）
			set targetLinks to ""
			if bookshelfState is "ready" then
				set targetLinks to (execute historyTab javascript "
	                       (function() {
	                               const links = [];
	                               const seen = new Set();
	                               const badges = document.querySelectorAll('.PCOM-prdList_badge_freeplus, .PCOM-prdList_badge_bingefree');
	                               for (let i = 0; i < badges.length && links.length < " & pageCount & "; i++) {
	                                       const badge = badges[i];
	                                       const link = badge.closest('a');
	                                       if (link && link.href && !seen.has(link.href)) {
	                                               seen.add(link.href);
	                                               links.push(link.href);
	                                       }
	                               }
	                               return links.join(',');
	                       })()
	               ") as text
			end if

			-- 取得したリンクを新しいタブで開く（開いた後にタブを読む処理はないので読み込み待ちは不要）
			if targetLinks is not "" then
				set linkList to my splitText(targetLinks, ",")
				repeat with linkURL in linkList
					make new tab with properties {URL:linkURL}
				end repeat
			end if
		end tell
	end tell

	set endTime to (current date)
	set elapsedSeconds to (endTime - startTime) as integer

	if showAlert then
		set alertMessage to "実行時間: " & elapsedSeconds & "秒"
		if bookshelfState is "no_target" then set alertMessage to "対象作品はありませんでした。" & return & alertMessage
		display alert "オープン完了" message alertMessage
	end if
end run

on splitText(theText, delimiter)
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiter
	set splitItems to text items of theText
	set AppleScript's text item delimiters to oldDelims
	return splitItems
end splitText

-- 固定delayの代わりに本棚ページの読み込み完了をポーリングで待ち、最終状態を返す
-- "ready": 対象バッジあり / "no_target": 作品リスト描画済みだが対象バッジなし / それ以外: 失敗（login_required, not_bookshelf, loading など）
-- 読み込み待ちとログイン検証を1つのJavaScriptに統合してあるので、ログイン切れはポーリング途中でも即座に確定する
on waitForBookshelfLoaded(theTab)
	set loadState to "script_error"
	repeat with attempt from 1 to 24
		set loadState to "script_error"
		try
			tell application "Google Chrome"
				set loadState to (execute theTab javascript "
					(function() {
						if (!location.hostname.endsWith('piccoma.com') || location.pathname !== '/web/bookshelf/bookmark') return 'not_bookshelf';
						if (document.querySelector('.PCOM-prdList_badge_freeplus, .PCOM-prdList_badge_bingefree')) return 'ready';
						const bodyText = (document.body ? document.body.innerText : '').trim();
						if (/ログインしてください|ログインが必要|ログインする|会員登録|メールアドレス|パスワード|login/i.test(bodyText)) return 'login_required';
						// 作品リンクは描画済みなのに対象バッジが無ければ、対象作品なしと確定して待たずに戻る
						if (document.readyState === 'complete' && document.querySelector('a[href*=\"/web/product/\"]')) return 'no_target';
						if (document.readyState !== 'complete') return 'loading';
						if (bodyText.length === 0) return 'empty';
						return 'rendering';
					})()
				") as text
			end tell
		end try
		if loadState is "ready" or loadState is "no_target" or loadState is "login_required" then return loadState
		-- 遷移直後は前ページのURLが見えることがあるため、not_bookshelfは約3秒粘ってから確定させる
		if loadState is "not_bookshelf" and attempt ≥ 10 then return loadState
		-- 読み込み完了の直後を逃さないよう序盤は短い間隔で、以降は0.5秒間隔に戻す
		if attempt ≤ 5 then
			delay 0.2
		else
			delay 0.5
		end if
	end repeat
	return loadState
end waitForBookshelfLoaded
