
find . -name \*.[ch] | xargs grep -n -e '\$Id' -e '\$Header' -e '\$Date' -e '\$DateTime' -e '\$Change' -e '\$File' -e '\$Revision' -e '\$Author'