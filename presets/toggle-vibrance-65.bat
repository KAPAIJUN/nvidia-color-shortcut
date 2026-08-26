@echo off
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0..\nvidia-color.ps1" -Action toggle -Type vibrance -On 65 -Off 50
