@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM ============================================================
REM OERIK IMAGE CONVERTER
REM
REM Converts:
REM   HEIC / HEIF
REM   JPG / JPEG
REM   PNG
REM
REM To:
REM   WebP
REM
REM Successful originals are MOVED to a backup folder
REM outside the Oerik-website directory.
REM ============================================================

set "ROOT=C:\Users\RichardMouton\Documents\Oerik-website\static\images"
set "BACKUP=C:\Users\RichardMouton\Documents\Oerik-image-backup"

echo.
echo ============================================================
echo   OERIK IMAGE CONVERTER
echo ============================================================
echo.
echo Source:
echo   %ROOT%
echo.
echo Backup:
echo   %BACKUP%
echo.

REM ------------------------------------------------------------
REM Verify ImageMagick
REM ------------------------------------------------------------

where magick >nul 2>&1

if errorlevel 1 (
    echo ERROR: ImageMagick was not found.
    echo.
    echo Make sure ImageMagick is installed and MAGICK.EXE
    echo is available in your Windows PATH.
    echo.
    pause
    exit /b 1
)

REM ------------------------------------------------------------
REM Create backup root
REM ------------------------------------------------------------

if not exist "%BACKUP%" mkdir "%BACKUP%"

REM ------------------------------------------------------------
REM Process supported image types
REM ------------------------------------------------------------

for /R "%ROOT%" %%F in (*.heic *.HEIC *.heif *.HEIF *.jpg *.JPG *.jpeg *.JPEG *.png *.PNG) do (
    call :CONVERT "%%~fF"
)

echo.
echo ============================================================
echo   IMAGE CONVERSION COMPLETE
echo ============================================================
echo.
pause
exit /b


:CONVERT

set "SOURCE=%~1"
set "SOURCE_DIR=%~dp1"
set "SOURCE_NAME=%~n1"
set "OUTPUT=%~dp1%~n1.webp"

REM Determine relative path beneath static\images
set "RELATIVE_DIR=%SOURCE_DIR:%ROOT%\=%"

REM Backup destination maintains folder structure
set "BACKUP_DIR=%BACKUP%\%RELATIVE_DIR%"

echo ------------------------------------------------------------
echo Source:
echo   %SOURCE%

REM ------------------------------------------------------------
REM Avoid overwriting an existing WebP
REM ------------------------------------------------------------

if exist "%OUTPUT%" (
    echo SKIPPED:
    echo   WebP already exists:
    echo   %OUTPUT%
    echo.
    goto :EOF
)

REM ------------------------------------------------------------
REM Convert
REM ------------------------------------------------------------

echo Converting to:
echo   %OUTPUT%

magick "%SOURCE%" ^
    -auto-orient ^
    -strip ^
    -quality 82 ^
    -define webp:method=6 ^
    "%OUTPUT%"

REM ------------------------------------------------------------
REM Verify successful conversion
REM ------------------------------------------------------------

if errorlevel 1 (
    echo.
    echo ERROR:
    echo   Conversion failed.
    echo   Original file was NOT moved.
    echo.
    if exist "%OUTPUT%" del /q "%OUTPUT%"
    goto :EOF
)

if not exist "%OUTPUT%" (
    echo.
    echo ERROR:
    echo   WebP file was not created.
    echo   Original file was NOT moved.
    echo.
    goto :EOF
)

REM ------------------------------------------------------------
REM Create matching backup directory
REM ------------------------------------------------------------

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM ------------------------------------------------------------
REM Move original into backup
REM ------------------------------------------------------------

move /Y "%SOURCE%" "%BACKUP_DIR%\" >nul

if errorlevel 1 (
    echo.
    echo WARNING:
    echo   WebP was created successfully,
    echo   but the original could not be moved.
    echo.
    goto :EOF
)

echo SUCCESS:
echo   WebP created.
echo   Original moved to:
echo   %BACKUP_DIR%
echo.

goto :EOF