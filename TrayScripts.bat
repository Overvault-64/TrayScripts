@echo off
setlocal

:: Get the directory where this batch file resides
set "ROOT=%~dp0"

:: Launch PowerShell with hidden window and proper paths (restored)
start /B powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%ROOT%tray.ps1'"

endlocal 