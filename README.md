Small_Programs
==============

## 初期設定
リポジトリをクローンした後、以下の手順で初期設定を行ってください：

```bash
cd settings/git
./initialize
```
***
### SortSafari [Java]
 program for sorting bookmark of Safari.
***

### openAll [AppleScript]
 droplet for open all files in folder.
***

### ccp [Ruby]
 cp command extention enables consecutive target files.
***

### bot-gf [Ruby]
 auto pilot bot of Girlfriend beta.
***

### cli_dir_diff [Shell Script]
 Command line tool for Directory diff.

 #### install:
 `ln -s "$(pwd)/cli_dir_diff.sh" /usr/local/bin/cli_dir_diff` (Mac)

 #### usage:
 `cli_dir_diff DIR1 DIR2`

 #### environment variable:
  - `DIR_DIFF_COMMAND`  - diff command for each file(default: `diff`)
  - `DIR_DIFF_PAGER_COMMAND`  - pager command for each file(default: `less`)
***
