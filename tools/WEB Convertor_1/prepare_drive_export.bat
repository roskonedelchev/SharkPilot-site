@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

REM prepare_drive_export.bat (Windows 10/11) - no installs
REM Input: Drive ZIP export (html + images) OR extracted html + images folder
REM Output: <name>_web\index.html + <name>_web\assets\ (images)

set "INPUT=%~1"
if "%INPUT%"=="" (
  call :autodetect
) else (
  set "INPUT=%INPUT:"=%"
)

if "%INPUT%"=="" (
  echo.
  echo [ERROR] No input selected or detected.
  echo        Drag and drop a ZIP or HTML onto the BAT, or run with a path parameter.
  echo.
  goto :fail
)

if not exist "%INPUT%" (
  echo.
  echo [ERROR] Not found: "%INPUT%"
  echo.
  goto :fail
)

for %%F in ("%INPUT%") do set "EXT=%%~xF"

if /I "%EXT%"==".zip" (
  call :process_zip "%INPUT%"
  if errorlevel 1 goto :fail
  goto :ok
)

if /I "%EXT%"==".html" (
  call :process_html "%INPUT%"
  if errorlevel 1 goto :fail
  goto :ok
)

echo.
echo [ERROR] Only .zip or .html are supported.
echo.
goto :fail

:autodetect
set "CUR=%cd%"

REM Pick newest ZIP in current folder (if any)
for /f "delims=" %%Z in ('dir /b /a-d /o-d "%CUR%\*.zip" 2^>nul') do (
  set "INPUT=%CUR%\%%Z"
  echo [INFO] Auto-picked ZIP: "%%Z"
  exit /b 0
)

REM Else pick newest HTML
for /f "delims=" %%H in ('dir /b /a-d /o-d "%CUR%\*.html" 2^>nul') do (
  set "INPUT=%CUR%\%%H"
  echo [INFO] Auto-picked HTML: "%%H"
  exit /b 0
)

echo.
echo [INFO] No ZIP or HTML found in current folder.
exit /b 0

:process_zip
set "ZIP=%~1"
for %%F in ("%ZIP%") do (
  set "ZIPDIR=%%~dpF"
  set "BASE=%%~nF"
)
set "WORK=%ZIPDIR%%BASE%_work"
set "OUT=%ZIPDIR%%BASE%_web"

echo.
echo [INFO] ZIP  : "%ZIP%"
echo [INFO] OUT  : "%OUT%"
echo.

if exist "%WORK%" rmdir /s /q "%WORK%" >nul 2>&1
if exist "%OUT%"  rmdir /s /q "%OUT%"  >nul 2>&1
mkdir "%WORK%" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%WORK%' -Force" 1>nul 2>nul
if errorlevel 1 (
  echo [ERROR] Expand-Archive failed. Is the ZIP valid?
  exit /b 2
)

set "HTML="
for /r "%WORK%" %%H in (*.html) do (
  if "!HTML!"=="" set "HTML=%%~fH"
)

if "%HTML%"=="" (
  echo [ERROR] No .html found inside the ZIP.
  rmdir /s /q "%WORK%" >nul 2>&1
  exit /b 3
)

call :process_html "%HTML%" "%OUT%"
set "RC=%errorlevel%"
rmdir /s /q "%WORK%" >nul 2>&1
exit /b %RC%

:process_html
set "HTML=%~1"
set "HTML=%HTML:"=%"
for %%F in ("%HTML%") do (
  set "DIR=%%~dpF"
  set "BASE=%%~nF"
)

if "%~2"=="" (
  set "OUT=%DIR%%BASE%_web"
) else (
  set "OUT=%~2"
)
set "OUT=%OUT:"=%"

echo.
echo [INFO] HTML : "%HTML%"
echo [INFO] OUT  : "%OUT%"
echo.

if exist "%OUT%" rmdir /s /q "%OUT%" >nul 2>&1
mkdir "%OUT%" >nul 2>&1
mkdir "%OUT%\assets" >nul 2>&1

set "IMGDIR=%DIR%images"
if not exist "%IMGDIR%" (
  set "IMGDIR=%DIR%%BASE%_files"
)

if not exist "%IMGDIR%" (
  echo [ERROR] Images folder not found next to HTML.
  echo        Expected "images\" or "%BASE%_files\" in:
  echo        "%DIR%"
  exit /b 4
)

copy /Y "%HTML%" "%OUT%\index.html" >nul
if errorlevel 1 (
  echo [ERROR] Failed to copy to "%OUT%\index.html"
  exit /b 5
)

robocopy "%IMGDIR%" "%OUT%\assets" /E /NFL /NDL /NJH /NJS /NC /NS >nul
if %errorlevel% GEQ 8 (
  echo [ERROR] Robocopy failed while copying images.
  exit /b 6
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0prepare_drive_export_fix.ps1" ^
  -HtmlPath "%OUT%\index.html" ^
  -OldFolders "images,%BASE%_files" >nul

if errorlevel 1 (
  echo [WARN] HTML fix step failed (PowerShell policy?).
) else (
  echo [OK] HTML updated (paths + lazy + utf-8).
)

echo.
echo [DONE] Output ready:
echo        "%OUT%\index.html"
echo        "%OUT%\assets\..."
echo.
exit /b 0

:ok
echo.
echo [OK] Finished successfully.
goto :end

:fail
echo.
echo [FAIL] Finished with errors.
goto :end

:end
echo.
pause
exit /b
