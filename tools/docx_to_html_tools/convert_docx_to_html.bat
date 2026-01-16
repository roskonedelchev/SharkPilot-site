@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM convert_docx_to_html.bat  (Windows 10/11)
REM Конвертира .docx -> index.html + assets\ (снимки)
REM Изисква: pandoc в PATH
REM ============================================================

if "%~1"=="" goto :usage

set "DOCX=%~1"
set "DOCX=%DOCX:"=%"

if not exist "%DOCX%" (
  echo [ERROR] Не намирам файла: "%DOCX%"
  exit /b 2
)

where pandoc >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Не е намерен "pandoc" в PATH.
  echo        Инсталирай Pandoc и опитай пак.
  echo        (Пример с winget: winget install --id JohnMacFarlane.Pandoc -e)
  exit /b 3
)

for %%F in ("%DOCX%") do (
  set "DIR=%%~dpF"
  set "BASE=%%~nF"
)

set "OUT=%DIR%%BASE%_web"
if not exist "%OUT%" mkdir "%OUT%" >nul 2>&1

echo [INFO] Input:  "%DOCX%"
echo [INFO] Output: "%OUT%"
echo.

REM --extract-media="%OUT%" създава "%OUT%\media"
pandoc "%DOCX%" -f docx -t html -s ^
  --extract-media="%OUT%" ^
  -c "/assets/style.css" ^
  -o "%OUT%\index.html"

if errorlevel 1 (
  echo [ERROR] Pandoc върна грешка при конвертиране.
  exit /b 4
)

REM media -> assets (за съвместимост със сайта)
if exist "%OUT%\media" (
  if exist "%OUT%\assets" (
    echo [WARN] "%OUT%\assets" вече съществува. Няма да преименувам "media".
  ) else (
    ren "%OUT%\media" assets
  )
)

REM Поправи HTML: media/ -> assets/ ; lazy loading ; UTF-8
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0convert_docx_to_html_fix.ps1" ^
  -HtmlPath "%OUT%\index.html" >nul

echo [OK] Готово!
echo      Папка: "%OUT%"
echo      Копирай:
echo        %OUT%\index.html  ->  (repo)\public\doc-X\index.html
echo        %OUT%\assets\     ->  (repo)\public\doc-X\assets\
echo.
exit /b 0

:usage
echo.
echo Употреба:
echo   convert_docx_to_html.bat "^<path\to\file.docx^>"
echo.
exit /b 1
