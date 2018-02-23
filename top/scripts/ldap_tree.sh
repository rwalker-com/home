#!/bin/bash

# $1 is the uid of the manager
# $2 is a qualifying search string
# $* is a list of attributes to return for each person in the manager's tree
#
# for example, ldap_tree.sh rwalker employeetype=employeee uid
# return uids

function tree_uids()
{
    [[ -z $1 ]] && return

    declare srch=''
    declare -a uids=()

    for uid in "$@"
    do
        echo "${uid}"
        srch+='(manager=uid='"$uid"',ou=people,o=qualcomm)'
    done

    uids=( $(ldapsearch -x -h directory -b o=qualcomm '(|'"${srch}"')' uid | awk '/^uid:/ {print $2}') )

    tree_uids "${uids[@]}"
}

declare uid=$1
shift
declare filter=$1
shift

declare -a uids=( $(tree_uids ${uid}) )

[[ -z ${filter} || ${filter} == '-' ]] && filter='(objectClass=*)'

[[ ${filter:0:1} == '(' ]] || filter='('${filter}')'

filter='(&'${filter}'(|'

for uid in ${uids[*]}
do
    filter+='(uid='"${uid}"')'
done
filter+='))'

ldapsearch -x -h directory -b o=qualcomm "${filter}" "$@"
