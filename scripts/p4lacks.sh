#!/bin/bash

if [ ${#} == 0 ] 
then
    ${0} .
    exit $?
fi


find "${@}" -type f -print0 | \
   xargs -0 -s 16384 p4 fstat 2>&1 1>/dev/null | \
   grep "no such" | \
   sed 's/\(.*\) - no such file.*/"\1"/g' 


