@echo off
rem Launcher: runs open-nvidia-color.ps1 with a hidden console
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0open-nvidia-color.ps1"
