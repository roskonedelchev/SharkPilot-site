@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ------------------------------------------------------------
REM import_doc.bat (Windows 10/11)
REM Импортира export: <name>.html + <name>_files\
REM към:
REM   public\doc-X\index.html
REM   public\doc-X\assets\...
REM + поправя HTML (paths, charset, lazy loading)
REM + конвертира изображения към .webp (ако има инструмент)
REM ------------------------------------------------------------
REM Употреба:
REM   tools\import_doc.bat 1 "C:\path\Manual.html"
REM   tools\import_doc.bat 2 "C:\path\Manual.html" "C:\path\Manual_files"
REM
REM Настройки (по желание):
REM   set DELETE_ORIGINALS=1   (default 1)
REM   set WEBP_QUALITY=82      (default 82)
REM ------------------------------------------------------------

if "%~1"=="" goto :usage
if "%~2"=="" goto :usage

set "DOCNUM=%~1"
set "SRC_HTML=%~2"
set "SRC_HTML=%SRC_HTML:"=%"

if not exist "%SRC_HTML%" (
  echo [ERROR] Не намирам HTML файла: "%SRC_HTML%"
  exit /b 2
)

if "%DELETE_ORIGINALS%"=="" set "DELETE_ORIGINALS=1"
if "%WEBP_QUALITY%"=="" set "WEBP_QUALITY=82"

REM Repo root: приемаме, че скриптът е в tools\
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..") do set "REPO_ROOT=%%~fI"

set "DEST=%REPO_ROOT%\public\doc-%DOCNUM%"
set "DEST_ASSETS=%DEST%\assets"

if not exist "%REPO_ROOT%\public" (
  echo [ERROR] Не намирам папка "%REPO_ROOT%\public".
  echo        Провери структурата на репото.
  exit /b 3
)

if not exist "%DEST%" mkdir "%DEST%" >nul 2>&1
if not exist "%DEST_ASSETS%" mkdir "%DEST_ASSETS%" >nul 2>&1

for %%F in ("%SRC_HTML%") do (
  set "SRC_DIR=%%~dpF"
  set "BASE=%%~nF"
)

set "SRC_FILES=%SRC_DIR%%BASE%_files"
if not exist "%SRC_FILES%" (
  if not "%~3"=="" (
    set "SRC_FILES=%~3"
    set "SRC_FILES=!SRC_FILES:"=!"
  )
)

if not exist "%SRC_FILES%" (
  echo [ERROR] Не намирам папка с файлове към HTML.
  echo        Очаквах: "%SRC_DIR%%BASE%_files"
  echo        Или подай 3-ти параметър с път до папката (пример: "...\Manual_files").
  exit /b 4
)

echo [INFO] Repo root:        "%REPO_ROOT%"
echo [INFO] Import to:        "%DEST%"
echo [INFO] Source HTML:      "%SRC_HTML%"
echo [INFO] Source files dir: "%SRC_FILES%"
echo [INFO] WebP quality:     %WEBP_QUALITY%
echo [INFO] Delete originals: %DELETE_ORIGINALS%
echo.

copy /Y "%SRC_HTML%" "%DEST%\index.html" >nul
if errorlevel 1 (
  echo [ERROR] Не успях да копирам HTML към "%DEST%\index.html"
  exit /b 5
)

robocopy "%SRC_FILES%" "%DEST_ASSETS%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
if %errorlevel% GEQ 8 (
  echo [ERROR] robocopy върна грешка при копиране на assets.
  exit /b 6
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%import_doc_fix_html.ps1" ^
  -HtmlPath "%DEST%\index.html" ^
  -OldFolder "%BASE%_files" >nul
if errorlevel 1 (
  echo [WARN] HTML поправките не се изпълниха успешно.
) else (
  echo [OK] HTML paths + lazy loading обновени.
)

REM Detect converter
set "CONVERTER="
where cwebp >nul 2>&1 && set "CONVERTER=cwebp"
if "%CONVERTER%"=="" ( where magick >nul 2>&1 && set "CONVERTER=magick" )
if "%CONVERTER%"=="" ( where ffmpeg >nul 2>&1 && set "CONVERTER=ffmpeg" )

if "%CONVERTER%"=="" (
  echo [WARN] Не намерих инструмент за WebP (cwebp / ImageMagick / ffmpeg). Прескачам конвертиране.
  goto :done
)

echo [INFO] WebP converter: %CONVERTER%
echo [INFO] Converting images under "%DEST_ASSETS%" ...

call :convert_ext png
call :convert_ext jpg
call :convert_ext jpeg
call :convert_ext gif
call :convert_ext bmp
call :convert_ext tif
call :convert_ext tiff

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%import_doc_fix_html.ps1" ^
  -HtmlPath "%DEST%\index.html" ^
  -OldFolder "%BASE%_files" ^
  -ForceWebp 1 >nul

echo [OK] Готово: "%DEST%"
echo      Commit + Push към GitHub => Cloudflare Pages обновява сайта.

:done
exit /b 0

:convert_ext
set "EXT=%~1"
for /r "%DEST_ASSETS%" %%F in (*.%EXT%) do (
  set "IN=%%~fF"
  set "OUT=%%~dpnF.webp"
  if not exist "!OUT!" (
    if "%CONVERTER%"=="cwebp" (
      cwebp -q %WEBP_QUALITY% "!IN!" -o "!OUT!" >nul 2>&1
    ) else if "%CONVERTER%"=="magick" (
      magick "!IN!" -quality %WEBP_QUALITY% "!OUT!" >nul 2>&1
    ) else if "%CONVERTER%"=="ffmpeg" (
      ffmpeg -y -loglevel error -i "!IN!" -c:v libwebp -q:v %WEBP_QUALITY% "!OUT!" >nul 2>&1
    )
    if exist "!OUT!" (
      if "%DELETE_ORIGINALS%"=="1" del /q "!IN!" >nul 2>&1
    )
  )
)
exit /b 0

:usage
echo.
echo Употреба:
echo   tools\import_doc.bat ^<docNum^> "^<path\to\file.html^>" ["^<path\to\file_files^>"]
echo.
echo Пример:
echo   tools\import_doc.bat 1 "C:\Docs\Manual.html"
echo.
exit /b 1
