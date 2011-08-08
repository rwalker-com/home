#!/bin/bash

cd $(dirname ${0})

rsync --delete -aiz rsync://mirrors.xmission.com/cygwin .
