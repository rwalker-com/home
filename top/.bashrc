# bunch of random paths ordered in reverse order of precedence
declare -a paths=(
~/.cargo/bin
~/bin/*/
~/bin
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/bin
/sbin
)

for i in "${paths[@]}"
do
   if [[ :${PATH}: =~ :${i}: ]]
   then
       #echo $i already in PATH
       :
   elif [[ -d ${i} ]]
   then
       # echo adding $i
       PATH=${i}:${PATH}
   fi
done

export EDITOR=emacs
export VISUAL=${EDITOR}
export PS1='[\u@\h${STY:+(${STY#*.})} \W]\\$ '

[[ -z ${DISPLAY+x} ]] && export DISPLAY=localhost:0.0

case "$TERM" in
xterm*|rxvt*)
    PS1='\[\e]0;\u@\h \W\a\]'${PS1}
    ;;
*)
    ;;
esac

[[ -f ~/.bash_alias ]] && . ~/.bash_alias

shopt -s extglob
for f in ~/.bashrc.d/!(*~)
do
    [[ -f ${f} ]] && . "${f}"
done

[[ -f ~/.cvsrc ]] && . ~/.cvsrc

[[ -f ~/.p4rc ]] && . ~/.p4rc

[[ -f ~/.ccacherc ]] && . ~/.ccacherc


HISTSIZE=10000
HISTFILESIZE=1000000000

# disable accessibility bus when on ssh
[[ -n ${SSH_CLIENT} ]] && export NO_AT_BRIDGE=1

shopt -s checkwinsize

[[ -f ~/.bashrc.local ]] && . ~/.bashrc.local
