#!/bin/bash

if [ -z "$DIR_DIFF_COMMAND" ]; then
  DIR_DIFF_COMMAND="diff"
fi
if [ -z "$DIR_DIFF_PAGER_COMMAND" ]; then
  DIR_DIFF_PAGER_COMMAND="less"
fi

# check valid directory
function check_directory(){
  if [ ! -d $1 ]; then
    echo "invalid directory: $1"
    exit
  fi
}

# diff for each file
function file_diff(){
    echo $1
  # file is in only one dir. ex:'Only in test: 02.txt'
  if expr "$1" : "^Only in .*$" > /dev/null; then
    local dir=$(echo $1 | sed -e "s/Only in *\(.*\): \(.*\)/\1/")
    local file=$(echo $1 | sed -e "s/Only in *\(.*\): \(.*\)/\2/")
    $DIR_DIFF_PAGER_COMMAND $(printf "%s/%s" $dir $file)
  # file is in either dirs. ex:'Files test/01.txt and test1/01.txt differ'
  elif expr "$1" : "^Files .* differ$" > /dev/null; then
    local file1=$(echo $1 | sed -e "s/Files \(.*\) and \(.*\) differ/\1/")
    local file2=$(echo $1 | sed -e "s/Files \(.*\) and \(.*\) differ/\2/")
    $DIR_DIFF_COMMAND $file1 $file2 | $DIR_DIFF_PAGER_COMMAND
  else
    echo "unexpected argment! $1"
  fi
}

# check args
if [ $# -ne 2 ]; then
  echo 'argments shoud be 2 directory.'
  exit
fi

check_directory $1
check_directory $2


line=""
while :
do
  if [ "$line" == "q" ]; then
    echo "good bye!"
    exit
  fi
  file_diff "$(diff -qr $1 $2 | peco | xargs)"
  printf "command(q: quit, other: next diff): "
  read line
done
