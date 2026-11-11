@echo off
chcp 65001 >nul
title Armandala Game - server
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server\server.ps1"
pause
