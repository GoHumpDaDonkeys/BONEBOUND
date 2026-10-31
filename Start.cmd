@echo off
setlocal
set "BONEBOUND_AUTOIT=%ProgramFiles(x86)%\AutoIt3\AutoIt3.exe"
if not exist "%BONEBOUND_AUTOIT%" set "BONEBOUND_AUTOIT=%ProgramFiles%\AutoIt3\AutoIt3.exe"
if not exist "%BONEBOUND_AUTOIT%" (
 echo Install AutoIt 3 with the 32-bit runtime, then run this launcher again.
 pause
 exit /b 1
)
start "" "%BONEBOUND_AUTOIT%" "%~dp0Bonebound.au3"
