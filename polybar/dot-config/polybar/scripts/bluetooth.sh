#!/bin/sh

if [ "$(systemctl is-active bluetooth.service)" = "active" ]; then
    exit 0
else
    exit 1
fi
