#! /bin/bash


function vim() {
  sh vim/install.sh
}


if declare -f "$1" > /dev/null
then
  "$@"
else
 vim
fi 
