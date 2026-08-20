@echo off
title OERIK Hugo Server

cd /d "C:\Users\RichardMouton\Documents\Oerik-website"

echo.
echo ========================================
echo   STARTING OERIK HUGO SERVER
echo ========================================
echo.

hugo server --baseURL http://localhost:1313/ --appendPort=false

pause