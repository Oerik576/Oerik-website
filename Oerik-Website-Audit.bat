@echo off
setlocal

rem ================================================================
rem Oerik Website Size Audit
rem Place this BAT file in the root of the Oerik-website folder.
rem It creates a dated report in the audit subfolder.
rem No website files are changed, moved, or deleted.
rem ================================================================

set "ROOT=%~dp0"
set "AUDITDIR=%ROOT%audit"

if not exist "%AUDITDIR%" mkdir "%AUDITDIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "STAMP=%%I"
set "REPORT=%AUDITDIR%\Oerik-Website-Audit_%STAMP%.txt"

echo Auditing:
echo   %ROOT%
echo.
echo This may take a minute if the project contains many images or Git files.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'SilentlyContinue';" ^
  "$root = [System.IO.Path]::GetFullPath('%ROOT%');" ^
  "$report = '%REPORT%';" ^
  "$allFiles = @(Get-ChildItem -LiteralPath $root -File -Recurse -Force | Where-Object { $_.FullName -notlike ($root + 'audit\*') });" ^
  "$totalBytes = ($allFiles | Measure-Object Length -Sum).Sum;" ^
  "$lines = [System.Collections.Generic.List[string]]::new();" ^
  "$lines.Add('OERIK WEBSITE SIZE AUDIT');" ^
  "$lines.Add(('Generated: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')));" ^
  "$lines.Add(('Project:   {0}' -f $root));" ^
  "$lines.Add('');" ^
  "$lines.Add('SUMMARY');" ^
  "$lines.Add(('Files:       {0:N0}' -f $allFiles.Count));" ^
  "$lines.Add(('Total size:  {0:N2} MB ({1:N2} GB)' -f ($totalBytes / 1MB), ($totalBytes / 1GB)));" ^
  "$lines.Add('');" ^
  "$lines.Add('TOP-LEVEL FOLDERS');" ^
  "$lines.Add('Size MB      Files   Folder');" ^
  "$lines.Add('-------      -----   ------');" ^
  "$folders = Get-ChildItem -LiteralPath $root -Directory -Force | Where-Object { $_.Name -ne 'audit' } | ForEach-Object { $folderPath = $_.FullName; $items = @($allFiles | Where-Object { $_.FullName.StartsWith($folderPath + '\', [System.StringComparison]::OrdinalIgnoreCase) }); [PSCustomObject]@{ Name = $_.Name; Bytes = ($items | Measure-Object Length -Sum).Sum; Count = $items.Count } } | Sort-Object Bytes -Descending;" ^
  "foreach ($f in $folders) { $lines.Add(('{0,10:N2}  {1,9:N0}   {2}' -f ($f.Bytes / 1MB), $f.Count, $f.Name)) };" ^
  "$rootFiles = @($allFiles | Where-Object { $_.DirectoryName -eq $root.TrimEnd('\') });" ^
  "$rootBytes = ($rootFiles | Measure-Object Length -Sum).Sum;" ^
  "$lines.Add(('{0,10:N2}  {1,9:N0}   [files in project root]' -f ($rootBytes / 1MB), $rootFiles.Count));" ^
  "$lines.Add('');" ^
  "$lines.Add('LARGEST 50 FILES');" ^
  "$lines.Add('Size MB      Relative path');" ^
  "$lines.Add('-------      -------------');" ^
  "$allFiles | Sort-Object Length -Descending | Select-Object -First 50 | ForEach-Object { $relative = $_.FullName.Substring($root.Length); $lines.Add(('{0,10:N2}   {1}' -f ($_.Length / 1MB), $relative)) };" ^
  "$lines.Add('');" ^
  "$lines.Add('FILE TYPES BY TOTAL SIZE');" ^
  "$lines.Add('Size MB      Files   Extension');" ^
  "$lines.Add('-------      -----   ---------');" ^
  "$allFiles | Group-Object { if ([string]::IsNullOrWhiteSpace($_.Extension)) { '[none]' } else { $_.Extension.ToLowerInvariant() } } | ForEach-Object { [PSCustomObject]@{ Extension = $_.Name; Count = $_.Count; Bytes = ($_.Group | Measure-Object Length -Sum).Sum } } | Sort-Object Bytes -Descending | ForEach-Object { $lines.Add(('{0,10:N2}  {1,9:N0}   {2}' -f ($_.Bytes / 1MB), $_.Count, $_.Extension)) };" ^
  "$lines.Add('');" ^
  "$lines.Add('IMAGE TOTALS');" ^
  "$imageFiles = @($allFiles | Where-Object { $_.Extension -match '^\.(png|jpg|jpeg|gif|webp|tif|tiff|bmp|svg)$' });" ^
  "$imageBytes = ($imageFiles | Measure-Object Length -Sum).Sum;" ^
  "$lines.Add(('Image files: {0:N0}' -f $imageFiles.Count));" ^
  "$lines.Add(('Image size:  {0:N2} MB' -f ($imageBytes / 1MB)));" ^
  "$lines.Add(('Percent of project: {0:N1}%%' -f $(if ($totalBytes -gt 0) { 100 * $imageBytes / $totalBytes } else { 0 })));" ^
  "$lines.Add('');" ^
  "$lines.Add('COMMON HUGO OR DEVELOPMENT FOLDERS');" ^
  "$lines.Add('These may be omitted from a review ZIP when present. Do not delete them solely from this report.');" ^
  "$candidateNames = @('.git', 'public', 'resources', 'node_modules');" ^
  "foreach ($name in $candidateNames) { $path = Join-Path $root $name; if (Test-Path -LiteralPath $path) { $items = @(Get-ChildItem -LiteralPath $path -File -Recurse -Force); $bytes = ($items | Measure-Object Length -Sum).Sum; $lines.Add(('{0,-14} {1,10:N2} MB   {2,9:N0} files' -f $name, ($bytes / 1MB), $items.Count)) } else { $lines.Add(('{0,-14} [not present]' -f $name)) } };" ^
  "$lines.Add('');" ^
  "$lines.Add('NOTES');" ^
  "$lines.Add('- PNG, JPG, WEBP, GIF, and PDF files are already compressed and may not shrink much in a ZIP.');" ^
  "$lines.Add('- Hugo public output often duplicates files stored under static.');" ^
  "$lines.Add('- The .git folder contains repository history and is unnecessary for a website-review ZIP.');" ^
  "$lines.Add('- Keep source folders such as content, static, assets, themes, layouts, data, and configuration files.');" ^
  "$lines | Set-Content -LiteralPath $report -Encoding UTF8;" ^
  "Write-Host ('Audit complete: ' + $report)"

if errorlevel 1 (
    echo.
    echo The audit could not be completed.
    echo Verify that Windows PowerShell is available and try again.
    pause
    exit /b 1
)

echo.
echo Audit complete.
echo Report saved to:
echo   %REPORT%
echo.

start "" notepad "%REPORT%"
endlocal

