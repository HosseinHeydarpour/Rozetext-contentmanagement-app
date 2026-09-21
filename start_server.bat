@echo off
chcp 65001 >nul
title Instagram Content Manager - PC Server
cls

echo ================================================================
echo    🚀 Instagram Content Manager - Local PC Server
echo    مدیریت و برنامه‌ریزی محتوای اینستاگرام
echo ================================================================
echo.

:: Check Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH!
    echo Please install Node.js from https://nodejs.org/ and try again.
    echo خطای نودجی‌اس: لطفاً ابتدا Node.js را نصب کنید.
    echo.
    pause
    exit /b 1
)

cd /d "%~dp0server"

:: Check if node_modules exists
if not exist "node_modules\" (
    echo [INFO] Installing required dependencies (Express, Chokidar, Multer, QRCode)...
    echo در حال نصب پکیج‌های سرور، لطفاً شکیبا باشید...
    call npm install
    if %errorlevel% neq 0 (
        echo [ERROR] npm install failed!
        pause
        exit /b 1
    )
    echo [OK] Dependencies installed successfully.
    echo.
)

:: Run Server
echo [INFO] Starting server...
echo.
node server.js

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Server stopped with an error.
)
pause
