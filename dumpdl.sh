#!/bin/bash

#
# TODO: the http code consumes about 0.4-0.5 seconds per request loop
#       iteration.  Subtract out that overhead to get "net"
#

me=$(basename ${0%.*})

count=16
sleep=0
out=
trace=
#delay=
keepalive=100

function help()
{
    cat<<EOF
Usage: ${me} [OPTIONS] <URL>

Download an HTTP URL repeatedly and take a TCP dump.

OPTIONS:
    -n NUM    Number of times to download the URL.  NUM must not exceed 
                 the server's Keep-Alive request limit.  Defaults to 16.
    -s SEC    Number of seconds to delay before issuing the next
                 request.  In pipelining mode, the delay starts after 
                 the headers have been received from the previous request.
                 In non-pipelining mode, the delay starts after
                 both the headers *and* body have been received.
    -p        Pipeline requests when possible.  If this option is absent, 
                 ${me} waits for each request to complete before sleeping and
                 issuing the next request.
    -k NUM    Number of requests to issue on a single tcp connection 
                 (using keep-alive). Defaults to 100, but may be limited
                 by server.
    -o DIR    Place log and tcpdump output in DIR. Defaults to a usefully
                 unique name.
    -x        Bash xtrace mode.  Very verbose.

URL defaults to http://www.qualcomm.com/.

EOF

#    -P        Download in parallel (using wget).  Default is to make the 
#                 requests serially (using /dev/tcp/<host>/<port>).
#    -d        Time the URL retrieval first and use the result as the
#                 delay between request issuance.  If -s is also 
#                 specified, the sum of these two is used as the delay.
#
}

function error()
{
    echo "Error: ${me}: " "${1}"
}

while getopts ":k:s:o:n:xpP" opt
do
    case "${opt}" in
        s) sleep=${OPTARG};;
        p) pipeline=1;;
        P) parallel=1;;
        k) keepalive=${OPTARG}
            if (( ${keepalive} <= 0 ))
            then
                error "please specify a number greater than zero for keepalive."
                exit 1
            fi
            ;;
#        d) delay=0;;
        o) out=${OPTARG};;
        n) count=${OPTARG};;
        x) trace=1; set -x;;
        [?]) error "unknown option \"-${OPTARG}\""; help; exit 1;;
   esac
done
((OPTIND--))
shift ${OPTIND}

url="${1:-http://www.qualcomm.com/}"

function precision()
{
    local f=${1#*.}
    
    if [[ ${f} == ${1} ]]
    then
        echo -1
    else
        echo ${#f}
    fi
}

function norm1()
{
    local x=${1:-0.0}

    if [[ ${x/./} == ${x} ]]
    then
        x=${x}.0
    elif [[ ${x:0:1} == . ]]
    then
        x=0${x}
    fi
    if [[ ${x//./} != ${x/./} ]]
    then
        x=0.0
    fi
    echo ${x}
}

function trimzeroes()
{
    local x=${1:-0}

    while [[ ${x:0:1} == 0 && ${x} != 0 ]]
    do
        x=${x:1}
    done
    echo "${x}"
}

function sumx()
{
    local v=${1:-0.0}
    local n=${2:-0}
    local ret=0.0
    
    while (( ${n} > 0 ))
    do
        ret=$(sum ${v} ${ret})
        ((n--))
    done
    echo ${ret}
}

function diff()
{
    sum "${@}" -
}

function sum()
{
    local x=$(norm1 ${1})
    local y=$(norm1 ${2})
    local px=$(precision ${x})
    local py=$(precision ${y})
    local op=${3:-+}

    while (( ${px} < ${py} ))
    do
        x=${x}0
        ((px++))
    done
    while (( ${py} < ${px} ))
    do
        y=${y}0
        ((py++))
    done
    
    x=$(trimzeroes ${x//./})
    y=$(trimzeroes ${y//./})
    
    local sum
    ((sum=${x}${op}${y}))

    # add zeros back on if necessary...
    while (( ${px} > ${#sum}-1 ))
    do
        sum=0${sum}
    done
    
    while (( ${px} > 0 ))
    do
        if [[ ${sum:${#sum}-1} != 0 ]]
        then
            break
        fi
        sum=${sum:0:${#sum}-1}
        ((px--))
    done

    if (( ${px} > 0 )) 
    then
        local split=${#sum}-${px}
        
        sum=${sum:0:${split}}.${sum:${split}}
    fi

    if [[ ${sum:0:1} == . ]]
    then
        sum=0${sum}
    fi

    echo "${sum}"
}

function http_parseurl()
{
    local -A http_parseurl
    if [[ -z ${1} ]]
    then
        return 1
    fi
    http_parseurl[url]=${1}

    if [[ ${http_parseurl[url]} =~ "http://" ]]
    then
        http_parseurl[url]=${http_parseurl[url]:7}
    fi
    
    http_parseurl[host]=${http_parseurl[url]%%/*}
    http_parseurl[port]=${http_parseurl[host]#*:}
    
    if [[ ${http_parseurl[port]} == ${http_parseurl[host]} ]]
    then
        http_parseurl[port]=
    fi

    http_parseurl[host]=${http_parseurl[host]%:*}
    http_parseurl[host]=${http_parseurl[host],,}

    http_parseurl[path]=/${http_parseurl[url]#*/}
    
    if [[ ${http_parseurl[path]} == /${http_parseurl[url]} ]]
    then
        http_parseurl[path]=/
    fi

    if [[ -n ${2} ]]
    then
        eval ${2}=${http_parseurl[host]}
    fi
    if [[ -n ${3} ]]
    then
        eval ${3}=${http_parseurl[port]}
    fi
    if [[ -n ${4} ]]
    then
        eval ${4}=${http_parseurl[path]}
    fi
}

function http_recvheaders()
{    
    local logdest=/dev/null
    local conn=0
    local opt

    OPTIND=1
    while getopts "c:l:" opt
    do
        case "${opt}" in
            l) logdest=${OPTARG};;
            c) conn=${OPTARG};;
        esac
    done
    ((OPTIND--))
    shift ${OPTIND}


    # read start line
    if [[ -n ${2} ]]
    then
        local -a _line
        read -r -a _line<&${conn}

        eval ${2}[version]=\${_line[0]} ${2}[status]=\${_line[1]}
        echo "${_line[@]}" >> "${logdest}"
    fi
    
    # if they don't care about the headers, just dump 'em
    if [[ -z ${1} ]]
    then
        while true
        do
            local _line

            read -r _line <&${conn}
            
            echo "${_line}" >> "${logdest}"
            
            if [[ -z ${_line//$'\r'/} ]]
            then
                break
            fi
        done
    else
        # read headers until blank line
        while true
        do
            local _line
            
            read -r _line <&${conn}
            
            echo "${_line}" >> "${logdest}"
            
            _line=${_line/$'\r'/}
            if [[ -z ${_line} ]]
            then
                break
            fi
            
            local _name=${_line%%:*}
            _name=${_name// /}
            _name=${_name,,}
            
            if ! [[ ,${1,,}, =~ ,${_name}, ]]
            then
                continue
            fi
        
            local _value=${_line#*:}
        
            shopt -sq extglob
            _value=${_value/#+( )/}
            _value=${_value/%+( )/}
            shopt -uq extglob
        
            eval ${2}[${_name}]=\"\${_value}\"
        done
    fi
}

function http_connect()
{
    local host port    
    http_parseurl "${1}" host port
    local _conn

    exec {_conn}<>/dev/tcp/${host}/${port:-80}
    eval ${2}=\${_conn}
}

function http_sendheaders()
{
    local logdest=/dev/null
    local conn=1
    local opt

    OPTIND=1
    while getopts "c:l:" opt
    do
        case "${opt}" in
            l) logdest=${OPTARG};;
            c) conn=${OPTARG};;
        esac
    done
    ((OPTIND--))
    shift ${OPTIND}

    local host port path

    http_parseurl "${1}" host port path

    local method
    eval method=\${${2}[method]:-GET}

    local connection
    eval connection=\${${2}[connection]:-Keep-Alive}

    echo -e "${method} ${path:-/} HTTP/1.0\r\nHost: ${host}${port:+:${port}}\r\nConnection: ${connection}\r\n" >&${conn}
    echo -e "${method} ${path:-/} HTTP/1.0\r\nHost: ${host}${port:+:${port}}\r\nConnection: ${connection}\r\n" >> "${logdest}"

    local keys
    eval keys=\( \"\${\!${2}[@]}\" \)
    local key
    for key in "${keys[@]}"
    do
        if [[ ${key} == method || ${key} == connection ]]
        then
            continue
        fi
        local value
        eval value=\"\${${2}[${key}]}\"

        echo -e "${key}: ${value}\r\n" "${logcmd[@]}" >&${conn}

    done
    echo -e "\r\n" >&${conn}
    
}

function readx()
{
    if [[ -n ${1} ]]
    then
        dd bs=1 count=${1} 2>/dev/null
    else
        dd 2>/dev/null        
    fi
}


http_parseurl "${url}" host port path

hostname=$(uname -n)

out=${out:-${me}_${hostname}_${host}${port:+_${port}}_${path//\//}_s_${sleep}${pipeline:+_p}_k_${keepalive}}

mkdir -p ${out}
echo Info: ${me}: outputting to ${out} 1>&2

# prime the network, get document size...
size=$(wget -q -O - http://${host}${port:+:${port}}${path} 2>/dev/null | wc -c)

# benchmark the download to guess at delay between requests...
# answer is in seconds, with ms precision
#if [[ -n ${delay} ]]
#then
#
#    start=( $(</proc/uptime) )
#    wget -q -O/dev/null http://${host}:${port}${path} 2>/dev/null 1>/dev/null
#    end=( $(</proc/uptime) )
#    delay=$(diff ${end} ${start})
#    
#else
#    delay=0
#fi
#
#sleep=$(sum ${sleep} ${delay})
#

# sleep for requested time 
if [[ -n $(which usleep) ]]
then

    usleep=${sleep}
    
    if (( $(precision ${usleep}) == -1 ))
    then
        usleep=${usleep}.0
    fi
    
    while (( $(precision ${usleep}) < 6 ))
    do
        usleep=${usleep}0
    done
    
    sleepcmd=( usleep ${usleep//./} )
else
    sleepcmd=( sleep ${sleep} )
fi


declare overhead

# benchmark overhead first, assume send() is free
if ! (( ${parallel} ))
then
    declare conn
    http_connect "${url}" conn

    # benchmark overhead first, assume send() is free
    start=( $(</proc/uptime) )
    declare -A request=()
    
    request[connection]="Close"
    
    http_sendheaders -c ${conn} -l ${out}/log "${url}" request

    # total so far to construct request
    end=( $(</proc/uptime) )

    reqoverhead=$(diff ${end} ${start})
    
    # don't count networking read time
    resphdrs=$(while true
               do
                   declare _line
                   read -r _line
                   echo "${_line}"
                   if [[ -z ${_line//$'\r'/} ]]
                   then
                       break
                   fi
               done <&${conn})
    # close connection
    exec {conn}<>&-
    
    respoverhead=$(echo ${resphdrs} | (
            start=( $(</proc/uptime) )
            declare -A response=()
            http_recvheaders "content-length,connection" response
            end=( $(</proc/uptime) )
            echo $(diff ${end} ${start}))
           )

    overhead=$(sum ${reqoverhead} ${respoverhead})
else
    overhead=0
fi


tcpdump -w "${out}/pcap" -s 1500 "host ${host} and port ${port:-80}" &
pid=${!}
# wait for dumpcap to get ready?
sleep 2


if ! (( ${parallel} ))
then
    # now really start
    start=( $(</proc/uptime) )

    reqsleft=${count}

    while (( ${reqsleft} > 0 ))
    do
        declare conn
        http_connect "${url}" conn
        
        tokeep=${keepalive}

        # new connection, no need to wait for body to finish
        bodypid=0

        while (( ${reqsleft} > 0 ))
        do
            unset request
            declare -A request=()

            # last request or last to keep alive
            if (( ${reqsleft} == 1 || ${tokeep} == 1 ))
            then
                request[connection]="Close"
            fi
            
            http_sendheaders -c ${conn} -l ${out}/log "${url}" request
    
            if (( ${bodypid} ))
            then
                wait ${bodypid}
            fi
            unset response
            declare -A response=()

            http_recvheaders -c ${conn} -l ${out}/log "content-length,connection" response

            if (( ${pipeline} ))
            then
                readx ${response[content-length]} <&${conn} >> "${out}/log" &
                bodypid=${!}
            else
                readx ${response[content-length]} <&${conn} >> "${out}/log"
            fi

            ${sleepcmd[@]}
            ((reqsleft--))
            ((tokeep--))

            if ! [[ ${response[connection],,} =~ "keep-alive" ]]
            then
                exec {conn}<>&-
                break
            fi
        done
    done

    if (( ${bodypid} ))
    then
        wait ${bodypid}
    fi


    end=( $(</proc/uptime) )
else
    reqsleft=${count}
    start=( $(</proc/uptime) )
    end=$(while (( ${reqsleft} > 0 ))
        do 
        (wget -q -O- http://${host}${port:+:${port}}${path} >> ${out}/log && 
            uptime=( $(</proc/uptime) ) && echo ${uptime} ) &
        ${sleepcmd[@]}
        ((reqsleft--))
        done | sort -n | tail -1)
fi

kill ${pid}

elapsed=$(diff ${end} ${start})

slept=$(sumx ${sleep} ${count})
overhead=$(sumx ${overhead} ${count})

net=$(diff ${elapsed} $(sum ${slept} ${overhead}))

((bytes=${count}*${size}))

cat <<EOF | tee -a "${out}/summary"
Summary
=======
Elapsed:  ${elapsed}s
Slept:    ${slept}s
Overhead: ${overhead}s
Net:      ${net}s
Bytes:    ${bytes}

EOF

