@echo off
cls
title PHOENIX GOLF OMS - NAP DU LIEU TU EXCEL
echo =========================================================================
echo    PHOENIX CV GOLF - DANG XU LY NAP DU LIEU TU FILE EXCEL...
echo =========================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_from_excel.ps1"

echo.
pause
