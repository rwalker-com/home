#!/bin/ksh -f

scp -i ~/.ssh/id_rsa bdevx.qualcomm.com:/etc/passwd ~/tmp/bdevx_passwd 2>/dev/null > /dev/null
ypcat passwd > ~/tmp/yp_passwd

USERS=`awk -F: '{print $1}' ~/tmp/bdevx_passwd`

for i in ${USERS}
do
   case ${i} in
      root|bin|daemon|adm|lp|sync|shutdown|halt|mail|news|uucp|operator|games|gopher|ftp|nobody|vcsa|mailnull|rpm|rpc|xfs|rpcuser|nfsnobody|nscd|ident|radvd|apache|squid|pcap)
      	  ;;
      *)
      	  if grep ^${i}\: ~/tmp/yp_passwd | awk -F: '{print $2}' | grep '*' 2>/dev/null 1>/dev/null
          then
             echo "${i} disabled"
          fi
          if ! grep ^${i}\: ~/tmp/yp_passwd 2>/dev/null 1>/dev/null
          then
             echo "${i} gone"
          fi
      	  ;;
   esac
done