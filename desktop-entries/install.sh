#! /bin/bash

CURRENT_DIR=$(dirname $(readlink -f "$0"))
BROWSER=null
GEFORCE_URL=https://play.geforcenow.com/mall/
ICONS_DIR=$HOME/.local/share/icons
DESKTOP_ENTRIES_DIR=$HOME/.local/share/applications

function get_browser() {
  if [ -e /usr/bin/chromium ]
  then
    BROWSER='chromium'
  elif [ -e /usr/bin/chrome ]
  then
    BROWSER='chrome'
  fi
}

function download_icons() {
 geforce_icon_url=$(
  curl -s ${GEFORCE_URL} |
  grep 'rel="icon"' |
  sed -r 's/<link.*href="(.*)".*>/\1/' |
  xargs | rev | cut -c2- | rev
 )
 geforce_icon_url=${GEFORCE_URL}${geforce_icon_url}

 # Need to change, it should gets the original extension from URL
 curl -s ${geforce_icon_url} -o ${ICONS_DIR}/geforcenow.png
}
  

function geforce_now() {
  echo -n "Installing Geforce NOW... "
  get_browser

  if [ -z ${BROWSER} ]
  then
    echo "skipping. No supported browser found!"
    return
  fi

  download_icons

  final_file=${CURRENT_DIR}/geforcenow.desktop

  cp ${CURRENT_DIR}/geforcenow.base ${final_file}
  
  sed -i "s/%BROWSER%/${BROWSER}/" ${final_file}

  desktop-file-install --dir=$DESKTOP_ENTRIES_DIR $final_file

  echo "done"
}

function main() {
  geforce_now
}

main
