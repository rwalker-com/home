#!/bin/bash

wdcleanup()
{
  kill ${wdpid}
  exit ${1}
}

# catch control-C, etc., cleanup subshell below
trap wdcleanup INT

(sleep ${1} && kill $$) &
wdpid=$!

shift

echo doing "$@"  ...

"$@"

echo done.

# don't race my wd signal
sleep 1
wdcleanup 0
