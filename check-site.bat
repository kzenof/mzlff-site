@echo off
chcp 65001 >nul
title Proverka sayta MZLFF
cd /d "%~dp0"

echo.
echo ============================================
echo   Proverka ssylok i skriptov
echo   Opens manual-check.html in browser at the end
echo ============================================
echo.
echo Rezhimy:
echo   check-site.bat          - ssylki + python-chast skriptov
echo   check-site.bat push     - ssylki + polnye PS1 s git push
echo.

if /i "%~1"=="push" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\check-site.ps1" -Push
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\check-site.ps1"
)

set EXIT_CODE=%ERRORLEVEL%

echo.
echo ============================================
if %EXIT_CODE%==0 (
    echo   Vse proverki proshli uspeshno
) else (
    echo   Est oshibki: %EXIT_CODE%
)
echo ============================================
echo.
pause
exit /b %EXIT_CODE%
