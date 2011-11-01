#!/bin/bash

me=$(basename $0)

old=/tmp/${me}.${$}
new=/tmp/${me}.${$}.rand

mac="00A0$(printf %04x%04x ${RANDOM} ${RANDOM})"

adb pull /etc/firmware/wlan/volans/WCN1314_qcom_cfg.ini ${old} || exit $?

echo setting mac to ${mac}

sed "s/NetworkAddress=.*/NetworkAddress=${mac}/g;s/gEnableImps=1/gEnableImps=0/g;s/gEnableBmps=1/gEnableBmps=0/g" < ${old} > ${new} || exit ${?}

# remount /system rw
adb remount

adb push ${new} /etc/firmware/wlan/volans/WCN1314_qcom_cfg.ini

read -p "reboot? [Y/n]: " answer

if [ -z "${answer%%[Yy]*}" ]
then
  adb reboot
fi



