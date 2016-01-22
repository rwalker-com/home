#!/bin/bash

declare dest=${1}
shift

declare dir
for dir in "${@}"
do
    declare left=$(ls "${dir}/"*.jpg | wc -l)
    declare i=1
    while (( left > 0 ))
    do
        if [[ -f ${dir}/${i}.jpg ]]
        then
            cat "${dir}/${i}.jpg"
            ((left--))
        fi
        ((i++))
    done
done | ffmpeg -vcodec mjpeg -f image2pipe -i - -qscale 0.1 -y ${dest}

