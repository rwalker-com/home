#!/bin/sh

HOSTNAME=`uname -n`

if [ -f $HOME/.Xdefaults-$HOSTNAME ]; then
    xrdb $HOME/.Xdefaults-$HOSTNAME    # Load Users X11 resource database
else
    if [ -f $HOME/.Xdefaults ]; then
  	xrdb $HOME/.Xdefaults       # Load Users X11 resource database
    fi
fi

if [ -f $HOME/.xmodmap-$HOSTNAME ]; then
    xmodmap $HOME/.xmodmap-$HOSTNAME
fi

if [ -x /usr/bin/gnome-session ]; then
      exec gnome-session
else
  if [ -x /usr/bin/startkde ]; then
      exec startkde
  else
      twm &
      xsetroot -solid black
      exec xterm -n "Console: logout to stop Xsession" -T "Console: logout to stop Xsession" -geometry =80x12+0+0 -C -ls
  fi
fi

