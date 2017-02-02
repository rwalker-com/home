set /a i=0

set "orig=%1%"
set "oldpass=%orig%"

:iloop

set "newpass=%orig%%i%"

ntpasswd -p %oldpass% %newpass%

timeout 10

set "oldpass=%newpass%"

set /a i+=1

if %i% equ 20 timeout 90000

if %i% lss 40 goto:iloop

ntpasswd -p %oldpass% %orig%
