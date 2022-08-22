@echo off

:: Set working dir
cd %~dp0 & cd ..

set PAUSE_ERRORS=1
call bat\Password.bat
call bat\SetupSDK.bat
call bat\SetupApp.bat

set OPTIONS=-tsa none
call bat\Packager.bat

pause
