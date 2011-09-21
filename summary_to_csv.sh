#!/bin/bash

echo "non-parallel,"
echo "size,sleep,net,"
for size in 32 64 128 256 1024
do
    net=$(awk '/Net/ {print $2}' dumpdl_*${size}kB_s_0_p_k_100/summary|tr -d s)
    echo "${size},-1,${net},"
    for sleep in 0 0.5 1 1.5 2 2.5 3 3.5 4 4.5 5
    do
        net=$(awk '/Net/ {print $2}' dumpdl_*${size}kB_s_${sleep}_k_100/summary|tr -d s)
        echo "${size},${sleep},${net},"
    done
done

echo ","
echo ","
echo ","
echo ","
echo "parallel,"
echo "size,sleep,net,"

for size in 32 64 128 256 1024
do
    net=$(awk '/Net/ {print $2}' dumpdl_*${size}kB_s_0_p_k_1/summary|tr -d s)
    echo "${size},-1,${net},"
done

echo ","
echo ","
echo ","
echo ","
echo "serial, no keep-alive,"
echo "size,sleep,net,"

for size in 32 64 128 256 1024
do
    net=$(awk '/Net/ {print $2}' dumpdl_*${size}kB_s_0_k_1/summary|tr -d s)
    echo "${size},-1,${net},"
done



