@echo off
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0..\nvidia-color.ps1" -Action toggle -Type hue -On 15 -Off 0
