#!/bin/sh

tcpdump -s 0 -l -A "${@}" | 
awk '{ gsub("\r","") }
i > 0 { headers[i++]=$0; }
/GET .*? HTTP\/1\.[01]$/ { gsub(/^.*GET/, "GET"); headers[i++] = $0; }
/POST .*? HTTP\/1\.[01]$/ { gsub(/^.*POST/, "POST"); headers[i++] = $0; }
/HEAD .*? HTTP\/1\.[01]$/ { gsub(/^.*HEAD/, "HEAD"); headers[i++] = $0; }
/PUT .*? HTTP\/1\.[01]$/ { gsub(/^.*PUT/, "PUT"); headers[i++] = $0; }
/HTTP\/1\.[01] [0-9][0-9][0-9] .*/ { gsub(/^.*HTTP\/1\./, "HTTP/1."); headers[i++] = $0; }
NF==0 { for (j = 0; j < i; j++) print headers[j]; i = 0; }'



