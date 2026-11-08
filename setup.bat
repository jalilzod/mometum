@echo off
REM One-time setup for Windows.
cd /d "%~dp0"
echo Generating Android and iOS platform folders...
call flutter create . --org com.momentum --project-name momentum --platforms=android,ios || goto :error
echo Installing packages...
call flutter pub get || goto :error
echo Patching platform config for notifications...
call dart run tool/setup.dart || goto :error
echo.
echo Done! Connect a phone or start an emulator, then run:  flutter run
goto :eof

:error
echo.
echo Setup failed. Make sure Flutter is installed and on your PATH (run: flutter doctor).
exit /b 1
