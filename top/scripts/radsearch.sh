#!/bin/bash

xmax=${1:-20}
ymax=${2:-6}

for ((x=0; x<xmax; x++))
do
    echo "start: $x,$y"
    for ((y=0; y<x && y<ymax; y++))
    do
        for ((i=0; i<x; i++))
        do
            echo -n "  "
        done
        echo "|"
    done

    for ((i=0; i<x; i++))
    do
        echo -n "  "
    done

    echo -n -e '*\r'
    
    for ((b=x-1; b>=0 && y<ymax; b--))
    do
        for ((i=0; i<b; i++))
        do
            echo -n "  "
        done
        echo -n -e "--\r"
    done
    echo ""
    echo "========================================================================"
done

((x=xmax-1))
for (( y=x; y<ymax; y++))
do
    echo "start: $x,$y"
    for ((i=0; i<y; i++))
    do
        echo ""
    done

    for ((i=0; i<x; i++))
    do
        echo -n "  "
    done

    echo -n -e '*\r'
    
    for ((b=x-1; b>=0; b--))
    do
        for ((i=0; i<b; i++))
        do
            echo -n "  "
        done
        echo -n -e "--\r"
    done
    echo ""
    echo "========================================================================"
done


