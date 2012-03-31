#!/bin/bash
# spawnj: parallel execution of multiple jobs

function spawnj()
{
    declare -a zero=()
    declare num=1

    OPTIND=1
    while getopts ":h0n:" opt
    do
        case "${opt}" in
            h) printf %s "
Reads and spawn commands from stdin

Usage: spawnj [OPTIONS]

Options:

  -h       : print this message
  -n <NUM> : run NUM commands to run in parallel, defaults to 1
  -0       : command stream is zero-delimited instead of newline delimited

Examples:

 Fun with sleep (should take 2, not 3, seconds to complete):

     time (echo sleep 1; echo sleep 2) | spawnj -n 2

 Runs all the executable files in a directory called \"tests\", up to
   16 at a time:

     find tests -type f -a -executable -print0 | spawnj -n 16 -0

"
                return 0
                ;;
            0) zero=( -d $'\0' ) ;;
            n) num=${OPTARG};;
            [?]) echo "unknown option -\"${OPTARG}\""; return 1;;
        esac
    done
    ((OPTIND--))
    shift "${OPTIND}"
    
    # subshell to keep "set -m" from screwing up local shell
    # and keep __spawnj_one out of the environment
    
    declare respawns=0
    function __respawnj()
    {
        declare cmd=
        declare -a jobs=( $(jobs -pr) )
        
        while ((${#jobs[*]} < num)) && read -r "${zero[@]}" cmd
        do
            #echo cmd is \""${cmd}"\" >&2
            if [[ -n ${cmd} ]]
            then
                bash -c "${cmd}" &
            fi
            jobs=( $(jobs -pr) )
            #echo ${#jobs[*]} jobs: ${jobs[*]}
        done
    }
    
    # enable job control (to get CHLD)
    set -m
    # whenever we hear about a child exiting, respawnj
    trap "__respawnj" CHLD || return 1
        
    # trigger respawnj
    ( true )

    wait

    # clear 
    trap -- CHLD
}

if [[ ${0} =~ .*bash$ ]]
then
    return
fi

if [[ -z ${spawnj_DOTEST} ]]
then
    spawnj "${@}"
    exit $?
fi


#############################################################################
# tests, not seen unless spawnj_DOTEST is set
#############################################################################

function expect_elapsed_centiS()
{
    declare name=${1}
    shift
    declare lower=${1}
    shift
    declare upper=${1}
    shift
    declare start elapsed _

    function __failed()
    {
        echo \""${name}"\" exited error ${1}
    }

    read start _ < /proc/uptime
    "${@}" || failed ${?}
    read elapsed _ < /proc/uptime

    start=${start//./}
    elapsed=${elapsed//./}
    ((elapsed=elapsed-start))

    if ((elapsed > upper || elapsed < lower))
    then
        echo "${name}" took ${elapsed}cs, expected between ${lower}cs and ${upper}cs
        return 1
    fi
    return ${ret}
}

declare -A tests=(
    [" "]="empty 0 10"
    ["\n\n"]="allblank 0 10"
    ["\0\0"]="allblank_0 0 10"
    ["sleep 1\n\nsleep 1\n\n"]="blanklines 190 210 spawnj"
    ["sleep 1\0\0sleep 1\0\0"]="blanklines_0 190 210 spawnj -0"
    ["sleep 1\nsleep 2\nsleep 3\n"]="n_1_sleep123 590 610 spawnj"
    ["sleep 1\0sleep 2\0sleep 3\0"]="n_1_0_sleep123 590 610 spawnj -0"
    ["sleep 1\nsleep 2\nsleep 3\n"]="n_2_sleep123 390 410 spawnj -n 2"
    ["sleep 1\nsleep 2\nsleep 3\n"]="n_3_sleep123 290 310 spawnj -n 3"
    ["sleep 1\nsleep 2\nsleep 3\n"]="n_4_sleep123 290 310 spawnj -n 4"
    ["sleep 1\nsleep 1\nsleep 1\nsleep 1\nsleep 1\nsleep 1\n"]="n_3_sleep_6 190 310 spawnj -n 3"
    ["echo hi && sleep 1\necho there && sleep 1\n"]="n_1_echo_sleep1 90 110 spawnj -n 2"
)

ret=0

for i in "${!tests[@]}"
do
    if ! printf "${i}" | expect_elapsed_centiS ${tests[${i}]} >/dev/null 2>/dev/null
    then
        ((ret++))
    fi
done
exit ${ret}


