#!/bin/bash -x

usrlocal=${INSTALL_DIR:-/usr/local/bin}

# get git, subversion, repo, perforce
apt-get -y install subversion || exit $?
apt-get -y install git || exit $?

apt-get -y install curl || exit $?

if ! [ -x ${usrlocal}/repo ]
then
  curl http://android.git.kernel.org/repo > ${usrlocal}/repo && chmod 755 ${usrlocal}/repo || exit $?
fi

if ! [ -x ${usrlocal}/p4 ]
then
  curl http://filehost.perforce.com/perforce/r10.2/bin.linux26x86/p4 > ${usrlocal}/p4 && chmod 755 ${usrlocal}/p4 || exit $?
fi

# WebKit dev/build deps
# see http://trac.webkit.org/wiki/BuildingQtOnLinux 
apt-get -y install bison flex libqt4-dev libqt4-opengl-dev libphonon-dev \
  libicu-dev libsqlite3-dev libxext-dev libxrender-dev gperf libfontconfig1-dev \
  libphonon-dev g++ || exit $?

#     TODO: http://code.google.com/p/chromium/wiki/LinuxBuildInstructionsPrerequisites#System_Requirements
#           http://trac.webkit.org/wiki/BuildingGtk


# Android dev/build deps (some overlapping with above)
# see http://source.android.com/source/initializing.html
apt-get -y install git-core gnupg flex bison gperf build-essential \
  zip curl zlib1g-dev libc6-dev lib32ncurses5-dev ia32-libs \
  x11proto-core-dev libx11-dev lib32readline5-dev lib32z-dev \
  libgl1-mesa-dev g++-multilib mingw32 tofrodos || exit $?

# jdk 1.6 Gingerbread and newer

# add repo unless already there...
if [ -z "$(grep 'deb http://archive.canonical.com/ lucid partner' /etc/apt/sources.list)" ]
then
   add-apt-repository "deb http://archive.canonical.com/ lucid partner" || exit $?
   apt-get update || exit $?
fi

apt-get -y install sun-java6-jdk || exit $?

# AMSS Android dependencies
apt-get -y install libstdc++5 libc6-dev-i386 || exit $?
