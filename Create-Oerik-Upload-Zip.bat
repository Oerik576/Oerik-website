@echo off
setlocal EnableExtensions

rem ==================================================================
rem Create Oerik Website Upload ZIP
rem
rem Place this file in the root of the Oerik-website folder.
rem The archive is saved as:
rem   audit\Oerik-website_YYYY-MM-DD.zip
rem
rem Running it again on the same date overwrites that day's archive.
rem Website files are never changed or deleted.
rem ==================================================================

set "ROOT=%~dp0"
rem Remove the trailing backslash because Robocopy can misread a quoted
rem directory that ends in a backslash.
set "SITE=%ROOT:~0,-1%"
set "AUDITDIR=%SITE%\audit"

if not exist "%AUDITDIR%" mkdir "%AUDITDIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%I"

if not defined TODAY (
    echo ERROR: The current date could not be determined.
    pause
    exit /b 1
)

set "ZIPFILE=%AUDITDIR%\Oerik-website_%TODAY%.zip"
set "STAGE=%TEMP%\OerikWebsiteUpload_%RANDOM%_%RANDOM%"
set "STAGEROOT=%STAGE%\Oerik-website"

echo Creating an upload copy of the website...
echo.
echo Source:
echo   %SITE%
echo.
echo Archive:
echo   %ZIPFILE%
echo.
echo Excluded folders:
echo   .git
echo   audit
echo   public
echo   resources
echo   node_modules
echo.

if exist "%STAGE%" rd /s /q "%STAGE%"
mkdir "%STAGEROOT%"

rem Robocopy codes 0 through 7 indicate success or success with differences.
robocopy "%SITE%" "%STAGEROOT%" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP ^
    /XD "%SITE%\.git" "%SITE%\audit" "%SITE%\public" "%SITE%\resources" "%SITE%\node_modules"

set "ROBOCODE=%ERRORLEVEL%"
if %ROBOCODE% GEQ 8 (
    echo.
    echo ERROR: The temporary upload copy could not be created.
    echo Robocopy returned code %ROBOCODE%.
    if exist "%STAGE%" rd /s /q "%STAGE%"
    pause
    exit /b %ROBOCODE%
)

if exist "%ZIPFILE%" del /f /q "%ZIPFILE%"

echo Compressing the upload copy...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Compress-Archive -LiteralPath '%STAGEROOT%' -DestinationPath '%ZIPFILE%' -CompressionLevel Optimal -Force"

if errorlevel 1 (
    echo.
    echo ERROR: The ZIP archive could not be created.
    if exist "%STAGE%" rd /s /q "%STAGE%"
    pause
    exit /b 1
)

if exist "%STAGE%" rd /s /q "%STAGE%"

for %%I in ("%ZIPFILE%") do set /a "ZIPMB=%%~zI / 1048576"

echo.
echo Upload ZIP created successfully.
echo.
echo File:
echo   %ZIPFILE%
echo.
echo Approximate size: %ZIPMB% MB
echo.
echo Running this file again today will replace the existing ZIP.
echo.

explorer /select,"%ZIPFILE%"
endlocal
