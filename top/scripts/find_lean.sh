#!/bin/bash

afr=13.5
boost=10
verbose=0
dirs=

while getopts ":a:b:d:v" opt
do
    case "${opt}" in
        a) afr="${OPTARG}";;
        b) boost="${OPTARG}";;
        v) verbose=1;;
        d) dirs=( "${dirs[@]}" "${OPTARG}");;
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
        if (( ${#events[*]} == 1 ))
        then
            echo ${1}: ${#events[*]} event
        else
            echo ${1}: ${#events[*]} events
        fi
        if (( ${verbose} ))
        then
            for ((i=0; i < ${#events[*]}; i++))
            do
                echo ${events[${i}]}
            done
        fi
    fi
}

#function arraymember()
#{
#    local find=${1}
#    local x
#    shift
#    for x in "${@}"
#    do
#        if [[ ${x} == ${find} ]]
#        then
#            return 0
#        fi
#    done
#    return 1
#}

if (( ${#dirs[*]} ))
then
    for dir in "${dirs[@]}"
    do
        for file in $(find "${dir}" -type f -a -name \*.csv)
        do
            check "${file}" "${afr}"
        done
    done
fi

for file in "$@"
do
    check "${file}" "${afr}"
done

