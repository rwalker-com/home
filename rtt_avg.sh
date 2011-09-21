#!/bin/bash

samples=( $(awk '/RTT avg:/ {print $3}' */rl.txt ) )


( for i in ${samples[@]}
do 
    echo ". + " ${i}
done
echo ". / " ${#samples[@]} ) | bc -l | tail -1
