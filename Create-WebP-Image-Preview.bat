@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ==================================================================
rem Oerik Website WebP Preview Generator
rem
rem Place this file in the root of the Oerik-website folder.
rem It converts PNG, JPG, and JPEG files found under static\images.
rem
rem Preview output:
rem   audit\webp-preview\static\images
rem
rem The live website images are never changed, moved, or deleted.
rem Existing WebP preview files are overwritten when regenerated.
rem Requires ImageMagick 7 and its "magick" command.
rem ==================================================================

set "ROOT=%~dp0"
set "SITE=%ROOT:~0,-1%"
set "SOURCE=%SITE%\static\images"
set "PREVIEW=%SITE%\audit\webp-preview\static\images"
set "AUDITDIR=%SITE%\audit"
set "QUALITY=82"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%I"
set "REPORT=%AUDITDIR%\WebP-Conversion-Report_%TODAY%.txt"

echo Oerik Website WebP Preview Generator
echo.

if not exist "%SOURCE%" (
    echo ERROR: The expected image folder was not found:
    echo   %SOURCE%
    echo.
    echo Place this batch file in the root of the Oerik-website folder.
    pause
    exit /b 1
)

where magick >nul 2>nul
if errorlevel 1 (
    echo ERROR: ImageMagick 7 was not found.
    echo.
    echo Install ImageMagick for Windows and include the application directory
    echo in the system PATH. Then run this batch file again.
    echo.
    echo Official download page:
    echo   https://imagemagick.org/script/download.php#windows
    echo.
    pause
    exit /b 1
)

if not exist "%PREVIEW%" mkdir "%PREVIEW%"

set /a COUNT=0
set /a FAILED=0

echo Source:
echo   %SOURCE%
echo.
echo Preview output:
echo   %PREVIEW%
echo.
echo Converting images to WebP at quality %QUALITY%...
echo.

for /r "%SOURCE%" %%F in (*.png *.jpg *.jpeg) do call :CONVERT_ONE "%%~fF"

echo.
echo Preparing the conversion report...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$source = '%SOURCE%';" ^
    "$preview = '%PREVIEW%';" ^
    "$report = '%REPORT%';" ^
    "$originals = @(Get-ChildItem -LiteralPath $source -File -Recurse | Where-Object { $_.Extension -match '^\.(png|jpe?g)$' });" ^
    "$converted = @(Get-ChildItem -LiteralPath $preview -File -Recurse -Filter '*.webp');" ^
    "$originalBytes = ($originals | Measure-Object Length -Sum).Sum;" ^
    "$convertedBytes = ($converted | Measure-Object Length -Sum).Sum;" ^
    "$savedBytes = $originalBytes - $convertedBytes;" ^
    "$percent = if ($originalBytes -gt 0) { 100 * $savedBytes / $originalBytes } else { 0 };" ^
    "$lines = @(" ^
    "'OERIK WEBSITE WEBP CONVERSION REPORT'," ^
    "('Generated: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))," ^
    "('WebP quality: %QUALITY%')," ^
    "''," ^
    "('Original image files: {0:N0}' -f $originals.Count)," ^
    "('Original total size:  {0:N2} MB' -f ($originalBytes / 1MB))," ^
    "('WebP preview files:   {0:N0}' -f $converted.Count)," ^
    "('WebP total size:      {0:N2} MB' -f ($convertedBytes / 1MB))," ^
    "('Space saved:          {0:N2} MB' -f ($savedBytes / 1MB))," ^
    "('Reduction:            {0:N1}%%' -f $percent)," ^
    "''," ^
    "('Preview folder: {0}' -f $preview)," ^
    "''," ^
    "'No original website images were changed or deleted.'" ^
    ");" ^
    "$lines | Set-Content -LiteralPath $report -Encoding UTF8"

if errorlevel 1 (
    echo WARNING: Images were processed, but the report could not be written.
)

echo.
echo Conversion complete.
echo Successfully processed: %COUNT%
echo Failed:                 %FAILED%
echo.
echo Report:
echo   %REPORT%
echo.
echo Review the WebP images before making any changes to the live website.
echo.

if exist "%REPORT%" start "" notepad "%REPORT%"
explorer "%PREVIEW%"
exit /b 0

:CONVERT_ONE
set "INPUT=%~1"
set "NOEXT=%~dpn1"
set "RELNOEXT=!NOEXT:%SOURCE%\=!"
set "TARGET=%PREVIEW%\!RELNOEXT!.webp"

for %%D in ("!TARGET!") do if not exist "%%~dpD" mkdir "%%~dpD"

echo   !RELNOEXT!.webp
magick "!INPUT!" -strip -define webp:method=6 -quality %QUALITY% "!TARGET!"

if errorlevel 1 (
    set /a FAILED+=1
) else (
    set /a COUNT+=1
)
exit /b 0

