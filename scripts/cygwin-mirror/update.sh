#!/bin/bash

cd $(dirname ${0})

mirror=${1:-mirror}
cygwin=${mirror}/cygwin

retries=100
while ! ${mirror}/update-mirror.sh
do
   (( retries-- )) || exit 1
   sleep 5
done

wget http://www.cygwin.com/setup.exe -O ${cygwin}/setup.exe || exit 1
./seexe/seexe_glue.sh ${cygwin}/setup_no_verify.exe ${cygwin}/setup.exe --no-verify || exit 1

wget http://www.cygwin.com/setup-legacy.exe -O ${cygwin}/setup-legacy.exe || exit 1
./seexe/seexe_glue.sh ${cygwin}/setup-legacy_no_verify.exe ${cygwin}/setup-legacy.exe --no-verify || exit 1

wget http://www.cygwin.com/cygwin-icon.gif -O ${cygwin}/cygwin-icon.gif || exit 1
cp -f index.html ${mirror}

(cd ${cygwin} && ln -s . cygwin)

for i in ./update-*-package.sh
do
  ${i} ${mirror} release setup || exit 1
  ${i} ${mirror} release-legacy setup-legacy || exit 1
done
