#!/bin/bash

function chomp()
{
    local val=${1}

    (shopt -sq extglob

    val=${val/$'\r'/ }
    val=${val/$'\n'/ }
    val=${val/#+( )/}
    val=${val/%+( )/}
    echo "${val}")

    return 0
}


function xml_to_dom()
{
    local T= A= C=
    local tag=
    local idx=0
    declare -A tagidx=()

    local IFS=">"
    while read -r -d "<" T C
    do
        if [[ -z ${T} ]]
        then
            continue
        fi
        
        A=${T#* }
        [[ ${A} == ${T} ]] && A=
        
        T=${T%% *}
        if [[ ${A} =~ .*/ ]]
        then
            T=${T}/
            A=${A%/}
        fi

        T=$(chomp "${T}")
        A=$(chomp "${A}")
        
        if [[ ${T} =~ \?.* ]]
        then
            continue
        fi

        if [[ ${T:0:1} == / ]]
        then
            tag=${tag%/${T:1}}
            idx=${tag##*.}
            tag=${tag%.*}
        else
            tag=${tag:+${tag}.${idx}/}${T}
            if [[ -z ${tagidx[${tag}]} ]]
            then
                tagidx[${tag}]=0
            else
                ((tagidx[${tag}]++))
            fi
            idx=${tagidx[${tag}]}
        fi
        
        if [[ -n ${A} ]]
        then
            # TODO: parse attributes
            eval ${1}[\${tag}.\${idx}.a]=\${A}
        fi
        
        if [[ ${T} =~ .+/ ]]
        then
            eval ${1}[\${tag}.\${idx}]=
            tag=${tag%/${T}}
            idx=${tag##*.}
            tag=${tag%.*}
        fi

        local cur=$(eval echo \${${1}[\${tag}.\${idx}]})
        eval ${1}[\${tag}.\${idx}]=\${cur}\${C}
    done
}

declare -A doc=()
xml_to_dom doc

for tag in "${!doc[@]}"
do
    echo "[${tag}]=${doc[${tag}]}"
done
echo ""


#for tag in "${!doc[@]}"
#do
#    echo -n "${tag}"
#    if [[ -n ${attrs[${tag}]} ]]
#    then
#        echo -n " (${attrs[${tag}]})"
#    fi
#    echo " => \"${doc[${tag}]}\""
#    
#done
