#!/bin/bash

# host and path to dumpdl files
base=${1}

files=( 32kB 64kB 128kB 256kB 1024kB )

# non-pipelined tests, full keep-alive
for sleep in 0 0.5 1 1.5 2 2.5 3 3.5 4 4.5 5
do
    for file in ${files[@]}
    do
        bash ./dumpdl.sh -s ${sleep} ${base}/${file}
    done
done

# pipelined tests (no sleep between requests, 100 requests per-connection)
for file in ${files[@]}
do
    bash ./dumpdl.sh -p ${base}/${file}
done

# no keep-alive, pipelining on (basically, parallel)
for file in ${files[@]}
do
    bash ./dumpdl.sh -p -k 1 ${base}/${file}
done

# no keep-alive, no pipelining, serial, connection per request
for file in ${files[@]}
do
    bash ./dumpdl.sh -k 1 ${base}/${file}
done

