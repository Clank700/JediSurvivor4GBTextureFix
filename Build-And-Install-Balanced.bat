@echo off
setlocal
cd /d "%~dp0"

echo Jedi Survivor 4 GB Texture Fix
echo.
echo This will:
echo   1. Build the three preset PAKs from your own installed game files.
echo   2. Install the Balanced preset.
echo.
echo No original game files will be modified.
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1"
if errorlevel 1 (
    echo.
    echo Build failed. Read the error above.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Switch-Preset.ps1" -Preset Balanced
if errorlevel 1 (
    echo.
    echo Install failed. Read the error above.
    pause
    exit /b 1
)

echo.
echo Balanced preset installed.
echo Start the game with ray tracing off and FSR Quality or Balanced.
pause

