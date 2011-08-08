#!/bin/bash -x

INFILE="${1}"
BASE=`basename "${INFILE}" .wav`

OUTFILE="${2}"/`dirname "${INFILE}"`/"${BASE}".mp3
OUTDIR=`dirname "${OUTFILE}"`

mkdir -p "${OUTDIR}"


ARTIST=`echo ${BASE} | awk -F" - " '{print $1}'`
ALBUM=`echo ${BASE} | awk -F" - " '{print $2}'`
TRACK=`echo ${BASE} | awk -F" - " '{print $3}'`
TITLE=`echo ${BASE} | awk -F" - " '{print $4}'`

echo INFILE   "${INFILE}"
echo BASE     "${BASE}"
echo OUTFILE  "${OUTFILE}"
echo ARTIST   "${ARTIST}"
echo ALBUM    "${ALBUM}"
echo TRACK    "${TRACK}"
echo TITLE    "${TITLE}" 


lame --tt "${TITLE}" --ta "${ARTIST}" --tl "${ALBUM}" --tn "${TRACK}" "${INFILE}" "${OUTFILE}"

