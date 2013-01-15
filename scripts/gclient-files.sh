#!/bin/bash

declare dir
gclient revinfo | cut -f1 -d: | while read dir
do
    (cd ${dir}
        declare ref=$(git log -1 --format=format:%H)
        declare file
        git ls-tree ${ref} --name-only -r | while read file
        do
            if [[ -d ${file} ]]
            then
                continue
            fi
            echo ${file}
        done
    )
done
