-- ピッコマの「¥0+」の漫画詳細ページをN件開く
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
	set theWindow to front window
	set theTabs to every tab of theWindow
	set tabCount to count of theTabs

	-- お気に入りページを新しいタブで開く
	tell theWindow
		make new tab with properties {URL:"https://piccoma.com/web/bookshelf/bookmark"}
		set historyTab to active tab
		delay 3 -- ページの読み込みを待つ

		-- 無料プラスバッジを持つリンクを取得
		set freePlusLinks to (execute historyTab javascript "
                       (function() {
                               const links = [];
                               const badges = document.querySelectorAll('.PCOM-prdList_badge_freeplus');
                               for (let i = 0; i < Math.min(badges.length, " & pageCount & "); i++) {
                                       const badge = badges[i];
                                       const link = badge.closest('a');
                                       if (link && link.href) {
                                               links.push(link.href);
                                       }
                               }
                               return links.join(',');
                       })()
               ") as text

		-- 取得したリンクを新しいタブで開く
		if freePlusLinks is not "" then
			set linkList to paragraphs of (do shell script "echo " & quoted form of freePlusLinks & " | tr ',' '
'")
			repeat with linkURL in linkList
				make new tab with properties {URL:linkURL}
				delay 1 -- 各タブの読み込みを少し待つ
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