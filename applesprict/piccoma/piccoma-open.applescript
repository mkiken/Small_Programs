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
		my waitForBookshelfLoaded(historyTab)
		my assertBookshelfOpened(historyTab)

		-- 対象バッジを持つリンクを取得
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
		display alert "オープン完了" message "実行時間: " & elapsedSeconds & "秒"
	end if
end run

on splitText(theText, delimiter)
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiter
	set splitItems to text items of theText
	set AppleScript's text item delimiters to oldDelims
	return splitItems
end splitText

-- 固定delayの代わりに本棚ページの読み込み完了をポーリングで待つ
on waitForBookshelfLoaded(theTab)
	repeat with attempt from 1 to 20
		set loadState to "pending"
		try
			tell application "Google Chrome"
				set loadState to (execute theTab javascript "
					(function() {
						if (document.readyState !== 'complete') return 'loading';
						if (!document.body || document.body.innerText.trim().length === 0) return 'empty';
						if (document.querySelector('.PCOM-prdList_badge_freeplus, .PCOM-prdList_badge_bingefree')) return 'ready';
						return 'no_badge';
					})()
				") as text
			end tell
		end try
		if loadState is "ready" then return
		-- DOMは完成しているがバッジが出ない場合（対象作品なし等）は、描画待ちを数回だけ延長して先へ進む
		if loadState is "no_badge" and attempt ≥ 10 then return
		delay 0.5
	end repeat
end waitForBookshelfLoaded

on assertBookshelfOpened(theTab)
	set bookshelfState to "script_error"
	try
		tell application "Google Chrome"
			set bookshelfState to (execute theTab javascript "
				(function() {
					const bodyText = (document.body ? document.body.innerText : '').trim();
					if (!location.hostname.endsWith('piccoma.com') || location.pathname !== '/web/bookshelf/bookmark') {
						return 'not_bookshelf';
					}
					if (/ログインしてください|ログインが必要|ログインする|会員登録|メールアドレス|パスワード|login/i.test(bodyText)) {
						return 'login_required';
					}
					if (!document.body || bodyText.length === 0) {
						return 'not_loaded';
					}
					return 'ok';
				})()
			") as text
		end tell
	end try

	if bookshelfState is not "ok" then
		display alert "本棚を開けませんでした" message "ログイン状態を確認してから再実行してください。" as critical
		error number -128
	end if
end assertBookshelfOpened
