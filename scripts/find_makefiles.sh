#!/bin/bash

if [ "$1" == "-0" ]
then
    print0="-print0"
    shift
fi

find "$*" -iname \*.min ${print0} -o -iname \*.mak ${print0} -o -iname makefile ${print0}