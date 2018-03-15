#!/bin/bash


# $1 is the uid of the manager
# $2 is a qualifying search string
# $* is a list of attributes to return for each person in the manager's tree
#

function ldap_tree_uids()
{
    [[ -z ${1} ]] && return

    declare srch=
    declare -a uids=()

    for uid in "${@}"
    do
        printf '%s\n' "${uid}"
        srch+='(manager=uid='"${uid}"',ou=people,o=qualcomm)'
    done

    uids=( $(ldapsearch -x -h directory -b o=qualcomm '(|'"${srch}"')' uid | awk '/^uid:/ {print $2}') )

    ${FUNCNAME[0]} "${uids[@]}"
}

function ldap_tree_search()
{
    declare uid=${1}
    shift
    declare filter=${1}
    shift

    declare -a uids=( $(ldap_tree_uids ${uid}) )

    [[ -z ${filter} || ${filter} == '-' ]] && filter='(objectClass=*)'

    [[ ${filter:0:1} == '(' ]] || filter='('${filter}')'

    # big filter on command line is much faster than multiple searches...
    #
    filter='(&'${filter}'(|'

    for uid in ${uids[*]}
    do
        filter+='(uid='"${uid}"')'
    done
    filter+='))'

    ldapsearch -x -h directory -b o=qualcomm "${filter}" "${@}"

    # search per line of stdin, for some reason this is slower than
    #  a huge search string
    #
    # for uid in ${uids[*]}
    # do
    #     printf '%s\n' '&'"${filter}"'(uid='"${uid}"')'
    # done | ldapsearch -x -h directory -b o=qualcomm -c -f - '(%s)' "${@}"
    #

}

if [[ ${0} == ${BASH_SOURCE[0]} ]]
then
    ldap_tree_search "${@}"
fi
