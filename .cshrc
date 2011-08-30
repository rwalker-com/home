##############################################################################
#
#	.cshrc file
#	Initial setup file for both interactive and noninteractive C-Shells.
#
##############################################################################
#echo ".cshrc for $user..."

set path = ( $HOME/bin /bin /etc /sbin /usr/bin /usr/sbin )

foreach i ( /usr/gnu/bin /usr/ucb /usr/local/bin /usr/bin/X11 /usr/X11/bin /usr/openwin/bin /usr/bsd /usr/games /usr/ccs/bin /usr/local/java/bin /usr/contrib/bin /usr/contrib/bin/X11 )
  if ( -e $i ) then
    set path = ( $path $i )
  endif
end

if !( $?MANPATH ) then
setenv MANPATH 
endif

switch ( `uname -s` )
  case SunOS:
    setenv MANPATH $HOME/man:/usr/local/man:/usr/man:/usr/openwin/man:$MANPATH
    breaksw

  case HP-UX:
    setenv MANPATH $HOME/man:/usr/local/man:/usr/man:/usr/contrib/man:$MANPATH
    breaksw

  case Linux:
    setenv MANPATH $HOME/man:/usr/local/man:/usr/man:$MANPATH
    breaksw

  case SCO_SV:
    setenv MANPATH $HOME/man:/usr/man:/usr/lib/scohelp/man:scohelp:$MANPATH
    breaksw

  case IRIX:
    setenv MANPATH $HOME/man:/usr/share/catman:/opt/man:/usr/lib/SoftWindows/man:$MANPATH
    breaksw

  case AIX:
    setenv MANPATH $HOME/man:/usr/man:/usr/bin/man:/usr/dt/man:/usr/share/man:$MANPATH
    breaksw

  default:
    setenv MANPATH $HOME/man:/usr/man:/usr/bin/man:$MANPATH
    breaksw

endsw


## umask set for full group but no general privileges
umask 022
limit coredumpsize 500000

##
## skip remaining if not an interactive shell
##

set history = 200
set nonomatch
unset autologout

set prompt = "`whoami`@`hostname`> "

if(-e ~/.alias) then
  source ~/.alias
endif

if(`whoami` == root) then
  if(-e ~/.alias.root) then
    source ~/.alias.root
  endif
endif

if(-e ~/.local) then
  source ~/.local
endif

set path = ( $path . )


