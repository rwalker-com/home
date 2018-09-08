# bunch of random paths ordered in reverse order of precedence
declare -a paths=(
/usr/contrib/bin /usr/contrib/bin/X11
/usr/ucb /usr/bsd /usr/games /usr/ccs/bin /usr/local/java/bin
/usr/gnu/bin
/usr/bin/X11 /usr/X11/bin /usr/X11R6/bin /usr/openwin/bin
/sbin /bin
/usr/sbin /usr/bin
/opt/local/bin
/opt/local/sbin
/usr/local/bin
/usr/local/sbin
~/.cargo/bin
~/bin/*/
~/bin
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

declare -a manpaths=(
~/man
/usr/local/man
/usr/local/share/man
/usr/man
/usr/share/man
/usr/openwin/man
/usr/contrib/man
/usr/lib/scohelp/man
scohelp
/usr/share/catman
/opt/man
/usr/lib/SoftWindows/man
/usr/bin/man
/usr/dt/man
)
for i in "${manpaths[@]}"
do
   if [[ :${MANPATH}: =~ :${i}: ]]
   then
       # echo $i already in MANPATH
       :
   elif [[ -d ${i} ]]
   then
       # echo adding $i
       MANPATH=${MANPATH}:${i}
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
