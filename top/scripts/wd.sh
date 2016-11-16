#!/bin/bash

function wdcleanup()
{
    kill ${1} 2>/dev/null 1>/dev/null
    exit ${2}
}

(sleep ${1} && wdcleanup $$ 2) &
# catch control-C, etc., cleanup subshell
trap "wdcleanup $! 1" INT

shift
exec "$@"
