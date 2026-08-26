@echo off
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0..\nvidia-color.ps1" -Action toggle -Type gamma -On 1.2 -Off 1.0
