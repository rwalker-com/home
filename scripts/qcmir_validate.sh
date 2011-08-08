#!/bin/bash

diffs=0

if [ ${1} = "-f" ]
then
    FILES=$(cat ${2})
else
    FILES="${*}"
fi

for i in ${FILES}
do
    p4file=$(basename ${i})
    p4 print -q ${i} > ${p4file}
    localfile=$(find . -name ${p4file%%#*})
    if [ -z "${localfile}" ]
    then
        echo ack! no localfile for p4file=${p4file}
        exit 1
    fi

    if ! diff -q ${p4file} ${localfile} 2>&1 > /dev/null
    then
        (echo ======== diff ${p4file} ${localfile}; diff ${p4file} ${localfile}) | less
        let diffs=${diffs}+1
        echo p4file=${p4file} does not match localfile=${localfile} 
    else
        echo p4file=${p4file} matches localfile=${localfile} 
    fi
done

exit ${diffs}
#!/bin/bash

diffs=0

for i in $(cat ${1})
do
    p4file=$(basename ${i})
    p4 print -q ${i} > ${p4file}
    localfile=$(find . -name ${p4file%%#*})
    if [ -z "${localfile}" ]
    then
        echo ack! no localfile for p4file=${p4file}
        exit 1
    fi

    if ! diff -q ${p4file} ${localfile} 2>&1 > /dev/null
    then
        (echo ======== diff ${p4file} ${localfile}; diff ${p4file} ${localfile}) | less
        let diffs=${diffs}+1
        echo p4file=${p4file} does not match localfile=${localfile} 
    else
        echo p4file=${p4file} matches localfile=${localfile} 
    fi
done

exit ${diffs}
