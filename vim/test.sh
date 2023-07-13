#! /bin/bash

BASEDIR=$(dirname "$0")

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname $(readlink -f "$0"))

echo "$(pwd)"
echo "${BASEDIR}"
echo "$SCRIPT"
echo "$SCRIPTPATH"

