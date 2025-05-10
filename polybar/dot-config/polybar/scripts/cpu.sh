#!/bin/bash

mpstat=$(mpstat 1 1)
usage=$(echo $mpstat | grep -Po "(\d+,\d+)$" | sed "s/,/./")
percentage=$(echo "100 - $usage" | bc -l)
echo $percentage

if [[ "$percentage" -lt "1" ]]; then
    echo "scale=1; $percentage/1" | bc -l
else
    echo "scale=0; $percentage/1" | bc -l
fi

