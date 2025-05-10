#!/bin/env bash

FILENAME=$HOME/Imagens/Screenshots/$(date +"%Y-%m-%d-%T")-screenshot.png

scrot $FILENAME
notify-send "Captura salva em $FILENAME"
