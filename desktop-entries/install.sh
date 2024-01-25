#! /bin/bash

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
    else
        fmt_error "Not found supported browsers."
        exit
    fi
}

function download_icons() {
    local geforce_icon_path=$(
    curl -s ${GEFORCE_URL} |
        grep 'rel="icon"' |
        sed -r 's/<link.*href="(.*)".*>/\1/' |
        xargs | rev | cut -c2- | rev
    )

    curl -s "${GEFORCE_URL}${geforce_icon_url}" -o ${ICONS_DIR}/geforcenow.png
}


function geforce_now() {
    fmt_message "Installing Geforce NOW... "

    get_browser

    download_icons

    local desktop_file=${CURRENT_DIR}/geforcenow.desktop

    sed -i "s/%BROWSER%/\/usr\/bin\/${BROWSER}/" ${desktop_file}

    desktop-file-install --dir=$DESKTOP_ENTRIES_DIR $desktop_file
}

configure_desktop_entries() {
    fmt_title "Configuring Desktop files..."

    geforce_now
}
