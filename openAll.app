
--フォルダ内のファイルを全て開くドロップレット

on open theList
	repeat with curItem in theList
		--display dialog curItem as string
		--try
		openAll(curItem) of me
		--on error
		--	display dialog curItem as string
		--end try

	end repeat
end open

--ファイルを全て開く
on openAll(theFolder)
	tell application "Finder"
		set curFiles to every file of theFolder --ファイル処理
		repeat with aFile in curFiles
			open aFile
		end repeat

		-- フォルダ内にフォルダがあれば、同様に処理 (再帰呼び出し)
		set curFolders to every folder of theFolder
		repeat with aFolder in curFolders
			openAll(aFolder) of me
		end repeat
	end tell
end openAll