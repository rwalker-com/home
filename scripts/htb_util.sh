#!/bin/bash

dev=${DEVICE:-eth0}
prio=${PRIO:-100}
parent=${PARENT:-1}
tc=/sbin/tc

function rawlist()
{
    echo "### ${tc} qdisc show dev ${dev}"
    ${tc} qdisc show dev ${dev}
    echo ""

    echo "### ${tc} class show dev ${dev} parent ${parent}:0"
    ${tc} class show dev ${dev} parent ${parent}:0
    echo ""

    echo "### ${tc} filter show dev ${dev} parent ${parent}:0"
    ${tc} filter show dev ${dev} parent ${parent}:0
    echo ""

}

function list()
{
    classids="${@}"

    if [ -z "${classids}" ]
    then
        classids=$(${tc} qdisc show dev ${dev} | 
            awk '/^qdisc sfq/ {print $3}' |
            tr -d :)
    fi
    for i in ${classids}
    do
       rate=$(${tc} class show dev ${dev} parent ${parent}:0 | 
           awk '/^class htb.*leaf '${i}':/ {print $10}')
       if [ -z "${rate}" ]
       then
          echo Apparently no such class \"${i}\"... 1>&2
          exit 1
       fi
       cat<<EOF
-----------------------------------------------------------------
classid:
   $i 
rate: 
   $rate
filters:
EOF
       ${tc} filter show dev ${dev} parent ${parent}:0 | 
            awk '/flowid '${parent}':'${i}'/ { flowid = $17; };
                 /^ / { if (flowid == "'${parent}':'${i}'") print $0; }'
    done
}

function error()
{
    cat<<EOF 1>&2
Error: ${me}:  ${@}

EOF

}

function clear()
{
    classids="${1}"

    if [ -z "${classids}" ]
    then
        error "\"clear\" requires at least one input classid."
        usage
        exit 3
    fi
    
    for i in ${classids}
    do
        handles=$(${tc} filter show dev ${dev} parent ${parent}:0 | awk '/flowid '${parent}':'${i}'/ {print $8}')
        for j in ${handles}
        do
            ${tc} filter del dev ${dev} handle $j protocol ip prio 100 u32 || exit $?
        done
    done
    
}

function del()
{
    classids="${1}"

    if [ -z "${classids}" ]
    then
        error "\"del\" requires at least one input classid."
        usage
        exit 3
    fi

    clear ${classids}

    for i in ${classids}
    do
       ${tc} class del dev ${dev} classid ${parent}:${i} || exit $?
    done

    exit $?
}

function new()
{
    classid="${1}"
    rate="${2}"
    if [ -z "${classid}" ]
    then
        error "\"new\" requires an input classid."
        usage
        exit 3
    fi
    if [ -z "${rate}" ]
    then
        error "\"new\" requires that you specify a rate."
        usage
        exit 3
    fi
    
    if [ -z "$(${tc} qdisc show dev ${dev} | awk '/htb '${parent}':/')" ]
    then
        ${tc} qdisc add dev ${dev} root handle ${parent} htb default 0 r2q 100
    fi

    ${tc} class add dev ${dev} parent ${parent}: classid "${parent}:${classid}" htb rate "${rate}" || exit $?
    
    if ! ${tc} qdisc add dev ${dev} parent "${parent}:${classid}" handle "${classid}" sfq perturb 10
    then
       del ${classid}
       exit 1
    fi

    exit $?
}

function rate()
{
    classid="${1}"
    rate="${2}"
    if [ -z "${classid}" ]
    then
        error "\"rate\" requires an input classid."
        usage
        exit 3
    fi
    if [ -z "${rate}" ]
    then
        error "\"rate\" requires that you specify a rate."
        usage
        exit 3
    fi
    ${tc} class change dev ${dev} parent ${parent}: classid "${parent}:${classid}" htb rate "${rate}"
}

function add()
{
    classid="${1}"
    shift
    peers="${@}"
    if [ -z "${classid}" ]
    then
        error "\"add\" requires an input classid."
        usage
        exit 3
    fi
    if [ -z "${peers}" ]
    then
        error "\"add\" requires that you specify at least one peer."
        usage
        exit 3
    fi

    for i in ${peers}
    do
        addr=(${1/:/ })
        
        ip=${addr[0]}
        port=${addr[1]}

        # port specified?
        if [ -n "${port}" ]
        then
            ${tc} filter add dev ${dev} parent ${parent}:0 protocol ip prio ${prio} u32 match ip dst "${ip}" match ip dport "${port}" 0xffff classid "${parent}:${classid}"
        else
            ${tc} filter add dev ${dev} parent ${parent}:0 protocol ip prio ${prio} u32 match ip dst "${ip}" classid "${parent}:${classid}"
        fi
        
    done
}

function peertoipmatch()
{
    addr=(${1/:/ })

    ip=${addr[0]}
    ip=(${ip//./ })
    
    printf "%02x%02x%02x%02x\\/ffffffff" ${ip[0]} ${ip[1]} ${ip[2]} ${ip[3]}
    
    return $?
}

function peertoportmatch()
{
    addr=(${1/:/ })
    
    port=${addr[1]}
    
    if [ -n "${port}" ]
    then
        printf "%08x\\/0000ffff" ${port}
    fi
}

function rem()
{
    classid="${1}"
    shift
    peers="${@}"
    if [ -z "${classid}" ]
    then
        error "\"rem\" requires an input classid."
        usage
        exit 3
    fi
    if [ -z "${peers}" ]
    then
        error "\"rem\" requires that you specify at least one peer."
        usage
        exit 3
    fi
    
    for i in ${peers}
    do
        ipmatch=$(peertoipmatch ${i})
        portmatch=$(peertoportmatch ${i})

        if [ -n "${portmatch}" ]
        then
           handles=$(${tc} filter show dev ${dev} parent ${parent}:0 | 
            awk '/flowid '${parent}':'${classid}'/ { handle = $8; };
                 /'" ${ipmatch}"'/ { if (handle == portmatch) { print handle; portmatch = ""; } else { ipmatch = handle } };
                 /'" ${portmatch}"'/ { if (handle == ipmatch) { print handle; ipmatch = ""; } else { portmatch = handle } }; ')
        else
            handles=$(${tc} filter show dev ${dev} parent ${parent}:0 | 
             awk '/flowid '${parent}':'${classid}'/ { handle = $8; };
                  /'" ${ipmatch}"'/ { print handle }')
        fi
        
        if [ -z "${handles}" ]
        then
            error "can't find a matching filter in class $classid."
            exit 3
        fi

        for h in ${handles}
        do
            ${tc} filter del dev ${dev} handle ${h} protocol ip prio ${prio} u32
        done
    done

    return $?
}


function usage()
{
    cat<<EOF 1>&2
Usage: ${me} <command> [args]

Where command is one of:

list [classid ...]     List information about a class.  If no classid is 
                        given, list information about all classids.

new <classid> <rate>   Create a new class with id classid and rate. Classid 
                         must be a 16-bit hexadecimal number.

rate <classid> <rate>  Set the rate for the given class.

del <classid>          Deletes a class and removes all peers from the class.

clear <classid>        Removes all peers from a class.


add <classid> <peer> [peer ...   ]

                       Adds one or more peer (IP:PORT) to a class.

rem <classid> <peer>  [peer ...   ]

                       Removes one or more peers from a class.

EOF
}


me=$(basename ${0})
func=${1}

shift

case "${func}" in

rawlist)
        rawlist "$@"
;;

list)
        list "$@"
;;

new)
        new "$@"
;;

rate)
        rate "$@"
;;

del)
        del "$@"
;;

clear)
        clear "$@"
;;

add)
        add "$@"
;;

rem)
        rem "$@"
;;

*)
     usage
     exit 2

esac

exit $?
