#!/bin/bash

afr=13.5
boost=10
verbose=0

while getopts ":a:b:v" opt
do
    case "${opt}" in
        a) afr=${OPTARG};;
        b) boost=${OPTARG};;
        v) verbose=1;;
        [?]) error "unknown option \"-${OPTARG}\""; exit 1;;
   esac
done
((OPTIND--))
shift ${OPTIND}


function check()
{
    events=( $(awk -F, '{if ( ($19-0) >= '${afr}' && ($5-0) >= '${boost}' && ($6-0) >= 95) {print "time:" $1 ",afr:" $19 ",pre-boost:" $5 ",pedal:" $6  }}' ${1}) )

    if (( ${#events[*]} ))
    then
        echo ${1}: ${#events[*]} events
        if (( ${verbose} ))
        then
            for ((i=0; i < ${#events[*]}; i++))
            do
                echo ${events[${i}]}
            done
        fi
    fi
}


function arraymember()
{
    find=${1}
    shift
    for x in "${@}"
    do
        if [[ ${x} == ${find} ]]
        then
            return 0
        fi
    done
    return 1
}

exclude=( $@ )

for i in *.csv
do
    if ! arraymember "${i}" "$@"
    then
        check ${i} ${afr}
    fi
done

