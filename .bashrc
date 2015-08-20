# bunch of random paths..
declare paths="
~/bin
~/bin/*/
/usr/bin /usr/sbin
/bin /sbin
/etc
/usr/bin/X11 /usr/X11/bin /usr/X11R6/bin /usr/openwin/bin
/usr/local/bin
/opt/local/bin /opt/local/sbin
/usr/gnu/bin
/usr/ucb /usr/bsd /usr/games /usr/ccs/bin /usr/local/java/bin
/usr/contrib/bin /usr/contrib/bin/X11
"
for i in ${paths}
do
   if [[ :${PATH}: =~ :${i}: ]]
   then
       # echo $i already in PATH
       :
   elif [[ -d ${i} ]]
   then
       # echo adding $i
       PATH=${PATH}:${i}
   fi
done

declare manpaths="
~/man
/usr/man
/usr/share/man
/usr/local/man
/usr/local/shareman
/usr/openwin/man
/usr/contrib/man
/usr/lib/scohelp/man
scohelp
/usr/share/catman
/opt/man
/usr/lib/SoftWindows/man
/usr/bin/man
/usr/dt/man
/usr/share/man
"
for i in ${manpaths}
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

case "$TERM" in
xterm*|rxvt*)
    PS1='\[\e]0;\u@\h \W\a\]'${PS1}
    ;;
*)
    ;;
esac

[[ -f ~/.bash_alias ]] && . ~/.bash_alias


[[ -f ~/.bash_local ]] && . ~/.bash_local

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

# Android defense
export STAY_OFF_MY_LAWN=1
