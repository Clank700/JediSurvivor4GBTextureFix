@echo off
setlocal
cd /d "%~dp0"

echo Jedi Survivor 4 GB Texture Fix
echo.
echo This will build the three preset PAKs from your own installed game files.
echo It will NOT install anything automatically.
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

echo.
echo Build complete.
echo.
echo The generated preset files are in:
echo   %~dp0dist
echo.
echo Recommended manual install:
echo   Copy zz_JS4GB_Balanced_P9.pak into SwGame\Content\Paks
echo.
pause

