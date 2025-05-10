#!/bin/sh

while $(radeontop -d - -i 1 | grep --line-buffered -oP "gpu \K\d{1,3}"); do
    temperature=$(sensors -u amdgpu-pci-1200 | grep -oP "^\s+temp1_input:\s+[\+]*\K[\-]*\d+\.\d")
    # echo "${usage:00}%  ${temperature}°C"
done

