#!/bin/csh -f

if ( `uname` == "Linux" ) then
  set PS="ps wwaux"
else
  set PS="ps -ef"
endif

foreach i ( `$PS | grep "$1" | grep -v $0 | grep -v grep | awk '{print $2}'`)
    kill -9 $i >& /dev/null &
end

