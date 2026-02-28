@echo off
REM ============================================================
REM  ErgoGuard HK AI - Windows Setup Script
REM  Run this ONCE from inside the ergoguard_hk folder
REM  Usage: setup_windows.bat
REM ============================================================

echo.
echo  =============================================
echo   ErgoGuard HK AI - Project Setup
echo  =============================================
echo.

REM Step 1: Check Flutter is installed
flutter --version >NUL 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter not found. Please install Flutter first:
    echo         https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)
echo [OK] Flutter found

REM Step 2: Backup our lib/ and pubspec.yaml
echo.
echo [1/5] Backing up source files...
if not exist "_backup" mkdir "_backup"
xcopy /E /I /Q lib "_backup\lib" >NUL
copy pubspec.yaml "_backup\pubspec.yaml" >NUL
copy README.md "_backup\README.md" >NUL 2>&1
echo [OK] Source files backed up

REM Step 3: Generate fresh Android scaffolding
REM Flutter needs a temp project name without spaces
echo.
echo [2/5] Generating Android project structure...
cd ..
flutter create --org com.ergoguard --project-name ergoguard_hk --platforms android --no-pub ergoguard_hk_temp >NUL 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] flutter create failed. Make sure Flutter is properly set up.
    echo         Run: flutter doctor
    pause
    exit /b 1
)

REM Copy the generated android/ folder into our project
robocopy ergoguard_hk_temp\android ergoguard_hk\android /E /NFL /NDL /NJH /NJS >NUL

REM Clean up temp project
rmdir /S /Q ergoguard_hk_temp

cd ergoguard_hk
echo [OK] Android structure generated

REM Step 4: Restore our source files
echo.
echo [3/5] Restoring ErgoGuard source files...
rmdir /S /Q lib >NUL 2>&1
xcopy /E /I /Q "_backup\lib" lib >NUL
copy "_backup\pubspec.yaml" pubspec.yaml >NUL
rmdir /S /Q "_backup"
echo [OK] Source files restored

REM Step 5: Patch minSdk to 24 (required for ML Kit)
echo.
echo [4/5] Patching minSdk to 24...
powershell -Command "(Get-Content android\app\build.gradle) -replace 'minSdk\s*=?\s*flutter\.minSdkVersion', 'minSdk 24' | Set-Content android\app\build.gradle"
powershell -Command "(Get-Content android\app\build.gradle) -replace 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24' | Set-Content android\app\build.gradle"
echo [OK] minSdk patched

REM Step 6: flutter pub get
echo.
echo [5/5] Installing dependencies (flutter pub get)...
flutter pub get
if %ERRORLEVEL% neq 0 (
    echo [ERROR] flutter pub get failed. Check your internet connection.
    pause
    exit /b 1
)

echo.
echo  =============================================
echo   Setup complete!
echo  =============================================
echo.
echo  Next steps:
echo    1. Connect your Android phone via USB
echo    2. Enable USB Debugging on the phone
echo    3. Run:  flutter run
echo.
pause
