#! /bin/bash


function vim() {
  sh vim/install.sh
}

function desktop-entries() {
  sh desktop-entries/install.sh
}

if declare -f "$1" > /dev/null
then
  "$@"
else
 vim
 desktop-entries
fi 
