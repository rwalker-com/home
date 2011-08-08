#!/bin/bash

cd $(dirname $0)

cygwin=${1}/cygwin
release=${2}
setup=${3}

cp -af ${release}/make-3.81-4/* ${cygwin}/${release}/make || exit 1

pushd ${cygwin}/${release}/make > /dev/null || exit 1
   rm -f md5.sum
   md5sum * > md5.sum
popd > /dev/null

(sed "s/release/${release}/g;s/setup/${setup}/g" ${release}/setup.patch | patch -d ${cygwin} -N -p0) || exit 1

pushd ${cygwin} > /dev/null || exit 1
   bzip2 -c ${setup}.ini > ${setup}.bz2
   rm -f *.sig
popd > /dev/null
