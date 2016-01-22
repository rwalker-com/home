set /a i=0

set "orig=%1%"

set "oldpass=%orig%"

set "newpass=%orig%%i%"

ntpasswd -p %oldpass% %newpass%

set "oldpass=%newpass%"

:loop

set /a i+=1

set "newpass=%orig%%i%"

ntpasswd -p %oldpass% %newpass%

set "oldpass=%newpass%"

if %i% lss 30 goto:loop

ntpasswd -p %oldpass% %orig%
