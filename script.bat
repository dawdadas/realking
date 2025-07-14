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
        :: Same boot—already asked
        set "needAsk=0"
    ) else (
        :: New boot—ask again
        set "needAsk=1"
    )
) else (
    :: No marker file—first run ever
    set "needAsk=1"
)

if "%needAsk%"=="0" (
    cls
    echo [32m[+] Already spoofed this boot. Launching FiveM...[0m
    start "" "%fivem_path%"
    exit /b
)

:: ===== Spoofing steps (first run this boot) =====
cls
echo Fetching version info...
for /f "delims=" %%i in ('curl --silent --show-error https://raw.githubusercontent.com/dawdadas/realking/main/version.txt') do set "correctVersion=%%i"
for /f "delims=" %%j in ('curl --silent --show-error https://raw.githubusercontent.com/dawdadas/realking/main/update.txt') do set "updateLink=%%j"

set "updateNeeded=0"
:: Delete old versions if they don't match
for %%f in (realspooferv*.exe) do (
    for /f "tokens=2 delims=v" %%a in ("%%~nf") do (
        if "%%a" neq "!correctVersion!" (
            del /q "%%f"
            set "updateNeeded=1"
        )
    )
)

:: Download update if needed
if !updateNeeded! equ 1 (
    echo Downloading new spoofer version...
    curl --silent --show-error -o "realspooferv!correctVersion!.exe" "!updateLink!" && cls
)

:: Download if nothing exists
if not exist "realspooferv*!correctVersion!.exe" (
    echo Saving spoofer for first time...
    curl --silent --show-error -o "realspooferv!correctVersion!.exe" "!updateLink!" && cls > nul 2>&1
)

set "realspoofer_path=realspooferv!correctVersion!.exe"

:: Stop & remove vgk driver if present
cls
sc stop vgk > nul 2>&1
sc delete vgk > nul 2>&1

:: Start the spoofer
echo.
echo [33m[!] Waiting for spoofer to finish...[0m
start "" "%realspoofer_path%" > nul 2>&1

:wait_loop
timeout /t 2 > nul
tasklist /FI "IMAGENAME eq realspooferv!correctVersion!.exe" 2>NUL | find /I "realspooferv!correctVersion!.exe" > NUL
if "%ERRORLEVEL%"=="0" (
    goto wait_loop
)

:: Ask user for confirmation
cls
echo [32m[+] Successfully loaded[0m
echo [32m[+] You are already spoofed.[0m
echo.
echo [36m[?] Did you see the green success message? (Y/N)[0m
choice /c YN /n /m "> "
if errorlevel 2 (
    echo.
    echo [31m[-] Skipping FiveM launch. You can open it manually later.[0m
    exit /b
)

:: If Y selected
echo.
echo [32m[+] Launching FiveM...[0m
start "" "%fivem_path%"

:: ===== Mark that we've asked this boot =====
>"%stateFile%" echo %bootTime%

exit /b
