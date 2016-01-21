#
# GNU make-compatible $(subst from,to,in)
function subst()
{
    if [[ -z $1 && -z $3 ]]
    then
        echo -n "$2"
    else
        # non-extglob stuff
        declare from=${1//\\/\\\\}
        from=${from//\*/\\\*}
        from=${from//\[/\\\[}
        # extglob 
        from=${from//\?/\\\?}
        from=${from//\+/\\\+}
        from=${from//\@/\\\@}
        from=${from//\!/\\\!}
        from=${from//\(/\\\(}
        echo -n "${3//${from}/$2}"
    fi
}

#
# GNU make-compatible $(word n,list)
function word()
{
    [[ -z $1 || -n ${1//[0-9]/} ]] && return 1
    (( $1 < 1 )) && return 1

    declare IFS=$' '$'\t' # GNU make only uses ' ' and '\t' for words
    declare -a n=( $2 )
    echo -n "${n[$1-1]}"
}

#
# GNU make-compatible $(wordlist s,e,list)
function wordlist()
{
    [[ -z $1 || -n ${1//[0-9]/} ]] && return 1
    [[ -z $2 || -n ${2//[0-9]/} ]] && return 1
    (( $1 < 1 )) && return 1
    
    declare IFS=$' '$'\t' # GNU make only uses ' ' and '\t' for words
    declare -a n=( $3 )
    declare spaces=$3

    # save and set extglob
    {
        declare extglob=$(shopt extglob)
        shopt -sq extglob
        
        spaces=${spaces##+( |$'\t')}     # trim leading
        spaces=${spaces//[!( |$'\t')]/X} # IFS -> 'X'
        spaces=${spaces// /s}            # ' ' -> 's'
        spaces=${spaces//$'\t'/t}        # '\t' -> 't'
        spaces=${spaces//X/ }            # X -> ' '
        
        # restore extglob
        [[ ${extglob} =~ off ]] && shopt -u extglob
    }
    # retype to array of words of the form sss st
    declare -a spaces=( "" ${spaces} )

    declare i=$1-1
    
    (( i >= $2 )) && return 0
    # emit first guy without leading space
    echo -n "${n[i]}"
    ((i++))
    for (( ; i < $2 && i < ${#n[*]}; i++ ))
    do
        # emit rest with corresponding spaces
        declare space=${spaces[i]}
        space=${space//s/ }
        space=${space//t/$'\t'}
        echo -n "${space//s/ }${n[i]}"
    done
}

#
# GNU make-compatible $(words list)
function words()
{
    declare IFS=$' '$'\t' # GNU make only uses ' ' and '\t' for words
    declare -a n=( $1 )
    echo -n ${#n[*]}
}

if [[ ${0} =~ .*bash$ ]]
then
    return
fi

####
#### tests
####

if [[ -z ${bashlisp_DOTEST} ]]
then
    exit 0
fi

function expect()
{
    declare expected=$1
    shift
    declare got=
    
    if ! got=$( "${@}" )
    then
        echo "error: \"${*}\" failed"
        return 1;
    fi
    
    if [[ ${got} != "${expected}" ]]
    then
        echo "error: \"${*}\" expected \"${expected}\", got \"${got}\" ($(shopt extglob))"
        return 1
    fi
}

function shouldfail()
{
    "${@}" && echo "error: expected \"${*}\" to fail" && return 1
}

function make_exec()
{
    declare cmd=

    while (( ${#@} ))
    do
        cmd=${cmd}${1}','
        shift
    done
    cmd=${cmd/%,}  # whack last comma
    cmd=${cmd/,/ } # first comma -> space
    make -s -f - <<EOF
all:;
\$(info \$(call if,,,\$\$(${cmd})))
EOF
}

function makeexpect()
{
    expect "$(make_exec "${@}")" "${@}"
}

alltests="${alltests} subst"
function substtest()
{
    function _bothways()
    {
        declare a=${RANDOM}

        # should match
        expect ${a} subst "$1" ${a} "$1"

        # shouldn't match, even for patterns trying to hit "_"
        expect _ subst "$1" a _
    }
    # try to mess up, trying to make the pattern match "_"  in some cases
    for i in "" "/" "\_" "~" "(" "!" "+" "{" "[" "?" "*" "?(_)" "*(_)" "+(_)" "@(_)" "!(_)" "_$" "^_" "#_" "%_" ".*" "." "\\" "\n" "[_]" "$'_'" "(_)" "!(foo)"
    do
        _bothways "$i"
    done

    # test _
    makeexpect subst _ a _
    
    makeexpect subst "[a-z]" x abcd
    makeexpect subst "[a-z]" x "[a-z]"

}

alltests="${alltests} words"
function wordstest()
{
    makeexpect words ""
    makeexpect words "a"
    makeexpect words "a b"
    makeexpect words "a\ b"
    expect "$(tr '\n' x < $0 | awk '{w+=NF}END{print w}')" words "$(< $0)"
}

alltests="${alltests} word"
function wordtest()
{
    makeexpect word 1 "a b"
    makeexpect word 2 "a b"
    makeexpect word 3 "a b"
    shouldfail word -1 "a b"
    shouldfail word 0 "a b"
}

alltests="${alltests} wordlist"
function wordlisttest()
{
    shouldfail wordlist -1 100 "a b"
    shouldfail wordlist "" 100 "a b"
    shouldfail wordlist 1 "" "a b"
    shouldfail wordlist 1 -1 "a b"
    makeexpect wordlist 1 0 "a b"
    makeexpect wordlist 1 1 "a b"
    makeexpect wordlist 2 2 "a b"
    makeexpect wordlist 1 2 "a b c"
    makeexpect wordlist 1 2 "a  b c"
    makeexpect wordlist 1 3 " a  b c "
    makeexpect wordlist 1 3 "  a b  c  "
    makeexpect wordlist 1 3 "  a b$'\t'c  "
}

extglob=$(shopt extglob)

# test with original sense of shopt extglob
function dotests()
{
    [[ ${bashlisp_DOTEST} == "all" ]] && bashlisp_DOTEST=${alltests}
    [[ ${bashlisp_DOTEST} == "none" ]] && return 0

    for i in ${bashlisp_DOTEST}
    do
        ${i}test
    done
}

dotests

if [[ ${extglob} =~ off ]]
then
    # test with opposite sense and restore
    shopt -s extglob
    dotests
    shopt -u extglob
else
    shopt -u extglob
    dotests
    shopt -s extglob
fi


