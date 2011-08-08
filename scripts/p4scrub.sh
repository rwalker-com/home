#!/bin/bash

if [ ${#} == 0 ] 
then
   ${0} .
   exit $?
fi

# whack all files not in perforce
find "${@}" -type f -print0 | \
   xargs -0 -s 16384 p4 fstat 2>&1 1>/dev/null | \
   grep -e "no such" -e "not in client view" | \
   sed 's/\(.*\) - no such.*/"\1"/g;s/\(.*\) - .*not in client view.*/"\1"/g' | \
   xargs rm -f

# whack all empty directories
find "${@}" -type d | while read i
do
   tail=${i#${last}/}

   if [ "${tail}" != "${i}" ]
   then
      continue
   fi

   if [ -z "$(find "${i}" -type f -print -quit)" ]
   then
      rm -rf "${i}"
      last=${i%/}
   fi
done

