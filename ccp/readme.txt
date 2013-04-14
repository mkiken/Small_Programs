Consecutive cp


コピー先のファイル名に連番を使えるようにしたcpの拡張です。
MacOS X 10.5以上で使えます（ソースをいじればcpとRubyが使える環境であれば使えます）。
ccpファイルを実行パスの通っているところに置いてください。


使い方は基本的にcpと同じです。

usage: ccp [-R [-H | -L | -P]] [-fi | -n] [-apvX] source_file target_file

target_fileに[start..end]の記述をすることで連番でコピー出来ます。
範囲を指定する際、startとendの文字列長は同じ長さにしてください。[001..100]は成功しますが、[1..100]は失敗します。


例

ccp template.cpp [A..E].cpp
→ A.cpp, B.cpp, C.cpp, D.cpp, E.cpp


ccp a.txt a[10..15].txt
→ a10.txt, a11.txt, a12.txt, a13.txt, a14.txt, a15.txt




メモ

・target_fileに範囲が含まれていない場合は失敗するようにしています。


・zshだと[]の展開にファイルグロブが働いて上手く動かないので、
alias ccp='noglob ccp'
を.zshrcなどに書いてください。
