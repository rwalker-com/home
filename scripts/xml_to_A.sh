#!/bin/bash
# bash XML parser
# mostly a container for xml_to_A()...
# If the script is run standalone, the output looks like something 
#  you could pass as associative array initialization, e.g.:
#
#  declare -A foo=( $(xml_to_A.sh < foo.xml) )
# 
# That won't work, though ;)
#

function chomp()
{
    local val=${1}

    (shopt -sq extglob

    val=${val//$'\r'/ }
    val=${val//$'\n'/ }
    val=${val//$'\t'/ }
    val=${val/#+( )/}
    val=${val/%+( )/}
    echo "${val}")

    return 0
}


function xml_to_A()
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

        # comment
        if [[ ${T:0:3} == !-- ]]
        then
            # comment with a '>' in it....
            if [[ ! ${T} =~ .*-- ]]
            then
                while read -r -d ">" T
                do
                    if [[ ${T} =~ .*-- ]]
                    then
                        break
                    fi
                done
            fi
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
xml_to_A doc

for tag in "${!doc[@]}"
do
    echo "[${tag}]=${doc[${tag}]}"
done
echo ""


me=${0##*/}
me=${me%.*}

dotest=${me}_DOTEST
intest=${me}_INTEST

if [[ -n ${!dotest} && -z ${!intest} ]]
then
#    set -x
    export ${intest}=1

    function expect()
    {
        local expect=$(chomp "${1}")
        shift

        if ! got=$(chomp "$( "${@}" )")
        then
            return ${?}
        fi

        if [[ "${got}" != "${expect}" ]]
        then
            echo "${0}: error: \"${@}\" expected \"${expect}\" got \"${got}\""
            return 1
        fi
        return 0
    }

    declare -A tests=(
        [<x>x</x>]='[x.0]=x'
        [<x>x<y>y</y>z</x>]='[x.0]=xz [x.0/y.0]=y'
        [<x><y></y><y>y</y></x>]='[x.0]= [x.0/y.0]= [x.0/y.1]=y'
        [<x><y><z/></y><y>y<z/></y><y>y</y></x>]='[x.0]= [x.0/y.0/z/.0]= [x.0/y.0]= [x.0/y.1]=y [x.0/y.2]=y [x.0/y.1/z/.0]='
        [<x><b/>x</x>]='[x.0]=x [x.0/b/.0]='
        [<x><!----></x>]='[x.0]='
        [<x><!-- > --></x>]='[x.0]='
        [<x><!--$'\n'<>> $'\n'--></x>]='[x.0]='
    )

    ret=0

    for i in "${!tests[@]}"
    do
        if ! echo -n "${i}" | expect "${tests[${i}]}" ${0}
        then
            ((ret++))
        fi
    done
    exit ${ret}
fi

exit 0

