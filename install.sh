#!/bin/bash

# installs "top" into home directory as a set of links
function __t_d()
{
    if (( ${trace:-0} || ${dryrun:-0} ))
    then
        echo "${@}" >&2
    fi

    if (( ! ${dryrun:-0} ))
    then
        "${@}"
    fi
}

declare dryrun=0
declare trace=0


# keep items in this list as a link to the directory in git
declare -a dirlinks=(
    scripts
)
# everything else will be on a per-file basis

declare top=$(cd $(dirname ${0})&&pwd)/top

declare a=

declare usage="
Usage: install.sh [OPTIONS] [DEST]

Installs via symlinks into DEST directory. If unspecified,
      \"${HOME}\" is the default.

Options:
   -h     shows this message
   -f     force installation, overwriting targets in DEST
   -t     trace
   -n     dryrun

"
declare OPTIND=1
declare opt=
while getopts ":ntfh" opt
do
    case "${opt}" in
        h) printf %s "${usage}"; exit 0;;
        f) a=!;;
        n) dryrun=1;;
        t) trace=1;;
        :) printf "error: \"-%s\" requires an argument\n" "${OPTARG}" >&2; exit 1;;
        [?]) printf "error: unknown option \"-%s\"\n" "${OPTARG}" >&2; exit 1;;
    esac
done
((OPTIND--))
shift "${OPTIND}"

declare dest=${1:-~}

# find file exclusions exclusions
declare excludes=()
declare targets=()

for dirlink in "${dirlinks[@]}"
do
    declare target=${top}/${dirlink}

    excludes+=('-a' '!' '-wholename' ${target}'/*')
    targets+=( ${target} )
done

if (( ${trace:-0} ))
then
   echo find "${top}" -type f "${excludes[@]}" -print0 >&2
fi

while read -d $'\0' target
do
    targets+=( "${target}" )
done < <(find "${top}" -type f "${excludes[@]}" -print0)

# do it...
for target in "${targets[@]}"
do
    declare linkname=${dest}/${target#${top}/}

    if [[ -e ${linkname} || -h ${linkname} ]]
    then
        if [[ ${a} != '!' ]]
        then
            read -n 1 -p "overwrite ${linkname}? (y/n/!) " a
            echo ""
            case "${a}" in
                y|!) ;;
                *) continue;;
            esac
        fi
        __t_d rm -rf "${linkname}"
    fi
    __t_d mkdir -p "$(dirname "${linkname}")"
    __t_d ln -s "${target}" "${linkname}"
done
