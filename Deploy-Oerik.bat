@echo off
title OERIK Website Deployment

cd /d "C:\Users\RichardMouton\Documents\Oerik-website"

echo.
echo ========================================
echo   OERIK WEBSITE DEPLOYMENT
echo ========================================
echo.

echo Adding changed files...
git add .

echo.
echo Creating commit...
git commit -m "Update Oerik website"

git pull --rebase origin main

echo.
echo Pushing to GitHub...
git push origin main

echo.
echo ========================================
echo   DEPLOYMENT COMMANDS COMPLETE
echo ========================================
echo.
echo GitHub Actions will now build and deploy
echo the website.
echo.
pause