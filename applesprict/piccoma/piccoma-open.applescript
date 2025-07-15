-- ピッコマの「¥0+」の漫画詳細ページをN件開く
-- Chromeなどからサービスで呼んだり、osascriptコマンドで呼んだりとサービス経由だととても重いので、automatorからアプリケーションとして起動するとよい

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
                               for (let i = 0; i < Math.min(badges.length, 5); i++) {
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

display alert "オープン完了" message "実行時間: " & elapsedSeconds & "秒"