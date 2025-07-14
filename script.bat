@echo off
setlocal enabledelayedexpansion

:: ===== Variables =====
set "folder=%cd%"
set "stateFile=%~dp0boot_marker.txt"
set "fivem_path=%localappdata%\FiveM\FiveM.exe"

:: ===== Get last boot time =====
for /f "skip=1 tokens=1" %%B in ('wmic os get lastbootuptime') do if not defined bootTime set "bootTime=%%B"
set "bootTime=%bootTime:~0,14%"

:: ===== Determine if we need to ask this boot =====
set "needAsk=0"
if exist "%stateFile%" (
    set /p prevBoot=<"%stateFile%"
    if "%prevBoot%"=="%bootTime%" (
        set "needAsk=0"
    ) else (
        set "needAsk=1"
    )
) else (
    set "needAsk=1"
)

if "%needAsk%"=="0" (
    cls
    echo [37m[+] Already spoofed this boot. Launching FiveM...[0m
    start "" "%fivem_path%"
    exit /b
)

:: ===== Spoofing steps (first run this boot) =====
cls
echo [37mFetching version info...[0m
for /f "delims=" %%i in ('curl --silent --show-error https://raw.githubusercontent.com/dawdadas/realking/main/version.txt') do set "correctVersion=%%i"
for /f "delims=" %%j in ('curl --silent --show-error https://raw.githubusercontent.com/dawdadas/realking/main/update.txt') do set "updateLink=%%j"

set "updateNeeded=0"
for %%f in (realspooferv*.exe) do (
    for /f "tokens=2 delims=v" %%a in ("%%~nf") do (
        if "%%a" neq "!correctVersion!" (
            del /q "%%f"
            set "updateNeeded=1"
        )
    )
)

if !updateNeeded! equ 1 (
    echo [37mDownloading new spoofer version...[0m
    curl --silent --show-error -o "realspooferv!correctVersion!.exe" "!updateLink!" && cls
)

if not exist "realspooferv*!correctVersion!.exe" (
    echo [37mSaving spoofer for first time...[0m
    curl --silent --show-error -o "realspooferv!correctVersion!.exe" "!updateLink!" && cls > nul 2>&1
)

set "realspoofer_path=realspooferv!correctVersion!.exe"

cls
echo [37mStopping old driver service...[0m
sc stop vgk > nul 2>&1
sc delete vgk > nul 2>&1

echo.
echo [37mStarting spoofer...[0m
start "" "%realspoofer_path%" > nul 2>&1

:wait_loop
    timeout /t 2 > nul
    tasklist /FI "IMAGENAME eq realspooferv!correctVersion!.exe" 2>nul | find /I "realspooferv!correctVersion!.exe" > nul
    if "%ERRORLEVEL%"=="0" goto wait_loop

:: ===== Stylized confirmation message & prompt =====
cls
echo.
echo [32m[DONE][37m Loaded Successfully[0m
echo.
echo [37mdid u get this message? (Y/N)[0m
choice /c YN /n /m "> "
if errorlevel 2 (
    echo.
    exit /b
)

:: ===== Launch FiveM & mark this boot =====
echo.
echo [37m[+] Launching FiveM...[0m
start "" "%fivem_path%"

>"%stateFile%" echo %bootTime%

exit /b
