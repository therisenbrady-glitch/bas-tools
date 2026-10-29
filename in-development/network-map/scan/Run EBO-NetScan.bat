@echo off
rem Runs EBO-NetScan.ps1 from this folder without changing the PC execution policy.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0EBO-NetScan.ps1" %*
pause
