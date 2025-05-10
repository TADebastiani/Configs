#!/bin/sh

usage=$(radeontop -d - -l 1 | grep --line-buffered -oP "gpu \K\d{1,3}" | bc -l)

temperature=$(sensors -u amdgpu-pci-1200 | grep -oP "^\s+temp1_input:\s+[\+]*\K[\-]*\d+\.\d" | bc -l)

printf "%02d%% %s°C\n" $usage $temperature
exit 0
