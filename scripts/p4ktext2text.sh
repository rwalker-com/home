#!/bin/bash

p4 files ... | grep -v ' - delete' | grep '\(ktext\)' | awk -F# '{print "\"" $1 "\""}' | xargs -s 16384 p4 edit -t text

#find . -type f -printf "'%p' " | xargs -s 16384 p4 files 2>/dev/null | grep '(ktext)$' | awk '{print $1}'


