#!/bin/bash

if [ $# != 2 ]
then
    echo "Usage: ${0} <root> <port>"
    exit 1
fi

where=${1}
port=${2}


if [ ! -d ${where} ]
then
    echo "Error: ${0}: unable to find directory ${where}"
    exit 1
fi

where=$(cd ${where} && pwd)

# per-port directory exclusions
case ${port} in
    mac)
    excludes="win wince android qt gtk chromium skia efl brew v8"
    ;;

    *)
    echo "Error: $0: Unknown port \"${port}\".  Please choose one of mac,"
    exit 1
    ;;
esac

dirs=$(for i in $(find ${where} -iname \*.cpp -print -o -iname \*.c -print)
do
#    dups give you an idea of what to exclude
#    dups=$(find . -name $(basename $i) | grep -v $i)
#    if [ -n "${dups}" ]
#    then
#      echo ${i} duped by ${dups}
#    fi
     dirname $i
done | sort | uniq)

for j in ${excludes}
do
   dirs=$(echo ${dirs} | grep -v $j\$)
done

for i in ${dirs}
do
   echo path $i
done





