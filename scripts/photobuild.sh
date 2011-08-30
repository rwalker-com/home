#!/bin/tcsh

set DIR=`basename $PWD` 
cat <<EOF>index.html
<HTML>
<HEAD>
<TITLE>$DIR</TITLE>
</HEAD>
<BODY bgcolor=#ffffff>
<H1>$DIR</H1>
<p>
Pics:<table width="100%"><tr>
EOF
set IMAGES = `ls -tr *.jpg | sed 's/\.jpg//g'`
set i=0
foreach img ( $IMAGES )

  cat <<EOF>>index.html
<td>
<a href="$img.jpg" target="new"><img src="thumbnails/$img.jpg"><BR>$img</a>
EOF
  @ i = $i + 1
  if ( $i == 4 ) then
     set i=0
     cat <<EOF>>index.html
<tr>
EOF
  endif

end

cat <<EOF>>index.html
</table>
</BODY>
</HTML>
EOF
