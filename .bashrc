for i in  ${HOME}/bin /bin /usr/bin /sbin /usr/sbin /etc /usr/local/bin /usr/gnu/bin /usr/bin/X11 /usr/X11/bin /usr/X11R6/bin /usr/openwin/bin /usr/ucb /usr/bsd /usr/games /usr/ccs/bin /usr/local/java/bin /usr/contrib/bin /usr/contrib/bin/X11
do
   case :${PATH}: in
      *:${i}:*)
#         echo $i already in PATH
   	 ;;

      *)
         if [[ -d ${i} ]]
         then
#            echo adding $i
            PATH=${PATH}:${i}
         fi
         ;;
  esac
done

case `uname -s` in
  "SunOS")
    MANPATH=${HOME}/man:/usr/local/man:/usr/man:/usr/openwin/man:${MANPATH}
    ;;

  "HP-UX")
    MANPATH=${HOME}/man:/usr/local/man:/usr/man:/usr/contrib/man:${MANPATH}
    ;;

  "Linux")
    MANPATH=${HOME}/man:/usr/local/man:/usr/man:${MANPATH}
    ;;

  "SCO_SV")
    MANPATH=${HOME}/man:/usr/man:/usr/lib/scohelp/man:scohelp:${MANPATH}
    ;;

  "IRIX")
    MANPATH=${HOME}/man:/usr/share/catman:/opt/man:/usr/lib/SoftWindows/man:${MANPATH}
    ;;

  "AIX")
    MANPATH=${HOME}/man:/usr/man:/usr/bin/man:/usr/dt/man:/usr/share/man:${MANPATH}
    ;;

  "*")
    MANPATH=${HOME}/man:/usr/man:/usr/bin/man:${MANPATH}
    ;;
esac

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

for f in ~/.bashrc.d/*.sh
do
    [[ -f ${f} ]] && . "${f}"
done

[[ -f ~/.cvsrc ]] && . ~/.cvsrc

[[ -f ~/.p4rc ]] && . ~/.p4rc


HISTSIZE=10000
HISTFILESIZE=1000000000

STAY_OFF_MY_LAWN=1
