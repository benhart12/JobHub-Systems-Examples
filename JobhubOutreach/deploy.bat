@echo off
setlocal enabledelayedexpansion

:menu
cls
echo.
echo ============================================
echo   JobHub Outreach - Deployment Menu
echo ============================================
echo.
echo Select what to deploy:
echo.
echo   1. Hosting only
echo   2. Functions only
echo   3. Firestore Rules only
echo   4. Firestore Indexes only
echo   5. Hosting + Functions (no rules)
echo   6. Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto deploy_hosting
if "%choice%"=="2" goto deploy_functions
if "%choice%"=="3" goto deploy_rules
if "%choice%"=="4" goto deploy_indexes
if "%choice%"=="5" goto deploy_hosting_functions
if "%choice%"=="6" goto end
echo.
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto menu

:deploy_hosting
echo.
echo ============================================
echo   Deploying Hosting...
echo ============================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Firebase CLI not found in PATH.
    echo Please install Firebase CLI: npm install -g firebase-tools
    echo.
    pause
    goto menu
)

echo Checking Firebase login status...
firebase projects:list 2>&1
set login_check=%ERRORLEVEL%
if %login_check% neq 0 (
    echo.
    echo ERROR: Not logged in to Firebase or authentication failed.
    echo.
    echo Please run: firebase login
    echo.
    pause
    goto menu
)

echo.
echo Login check passed!
echo.
echo Current Firebase project:
firebase use
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Failed to get current Firebase project.
    echo Please run: firebase use [project-id]
    echo.
    pause
    goto menu
)

echo.
set /p confirm="Deploy hosting to this project? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Deployment cancelled.
    timeout /t 2 >nul
    goto menu
)

echo.
echo Deploying hosting...
echo.
firebase deploy --only hosting
set deploy_result=%ERRORLEVEL%

if %deploy_result% neq 0 (
    echo.
    echo ============================================
    echo ERROR: Hosting deployment failed!
    echo Error code: %deploy_result%
    echo ============================================
    echo.
    pause
    goto menu
)

echo.
echo ============================================
echo   Hosting deployment complete!
echo ============================================
pause
goto menu

:deploy_functions
echo.
echo ============================================
echo   Deploying Functions...
echo ============================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Firebase CLI not found in PATH.
    echo Please install Firebase CLI: npm install -g firebase-tools
    echo.
    pause
    goto menu
)

echo Checking Firebase login status...
firebase projects:list 2>&1
set login_check=%ERRORLEVEL%
if %login_check% neq 0 (
    echo.
    echo ERROR: Not logged in to Firebase or authentication failed.
    echo.
    echo Please run: firebase login
    echo.
    pause
    goto menu
)

echo.
echo Login check passed!
echo.
echo Current Firebase project:
firebase use
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Failed to get current Firebase project.
    echo Please run: firebase use [project-id]
    echo.
    pause
    goto menu
)

echo.
set /p confirm="Deploy functions to this project? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Deployment cancelled.
    timeout /t 2 >nul
    goto menu
)

echo.
echo Deploying functions...
echo.
firebase deploy --only functions
set deploy_result=%ERRORLEVEL%

if %deploy_result% neq 0 (
    echo.
    echo ============================================
    echo ERROR: Functions deployment failed!
    echo Error code: %deploy_result%
    echo ============================================
    echo.
    pause
    goto menu
)

echo.
echo ============================================
echo   Functions deployment complete!
echo ============================================
pause
goto menu

:deploy_rules
echo.
echo ============================================
echo   Deploying Firestore Rules...
echo ============================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Firebase CLI not found in PATH.
    echo Please install Firebase CLI: npm install -g firebase-tools
    echo.
    pause
    goto menu
)

echo Checking Firebase login status...
firebase projects:list 2>&1
set login_check=%ERRORLEVEL%
if %login_check% neq 0 (
    echo.
    echo ERROR: Not logged in to Firebase or authentication failed.
    echo.
    echo Please run: firebase login
    echo.
    pause
    goto menu
)

echo.
echo Login check passed!
echo.
echo Current Firebase project:
firebase use
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Failed to get current Firebase project.
    echo Please run: firebase use [project-id]
    echo.
    pause
    goto menu
)

echo.
set /p confirm="Deploy Firestore rules to this project? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Deployment cancelled.
    timeout /t 2 >nul
    goto menu
)

echo.
echo Deploying Firestore rules...
echo.
firebase deploy --only firestore:rules
set deploy_result=%ERRORLEVEL%

if %deploy_result% neq 0 (
    echo.
    echo ============================================
    echo ERROR: Firestore rules deployment failed!
    echo Error code: %deploy_result%
    echo ============================================
    echo.
    pause
    goto menu
)

echo.
echo ============================================
echo   Firestore rules deployment complete!
echo ============================================
pause
goto menu

:deploy_indexes
echo.
echo ============================================
echo   Deploying Firestore Indexes...
echo ============================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Firebase CLI not found in PATH.
    echo Please install Firebase CLI: npm install -g firebase-tools
    echo.
    pause
    goto menu
)

echo Checking Firebase login status...
firebase projects:list 2>&1
set login_check=%ERRORLEVEL%
if %login_check% neq 0 (
    echo.
    echo ERROR: Not logged in to Firebase or authentication failed.
    echo.
    echo Please run: firebase login
    echo.
    pause
    goto menu
)

echo.
echo Login check passed!
echo.
echo Current Firebase project:
firebase use
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Failed to get current Firebase project.
    echo Please run: firebase use [project-id]
    echo.
    pause
    goto menu
)

echo.
set /p confirm="Deploy Firestore indexes to this project? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Deployment cancelled.
    timeout /t 2 >nul
    goto menu
)

echo.
echo Deploying Firestore indexes...
echo.
firebase deploy --only firestore:indexes
set deploy_result=%ERRORLEVEL%

if %deploy_result% neq 0 (
    echo.
    echo ============================================
    echo ERROR: Firestore indexes deployment failed!
    echo Error code: %deploy_result%
    echo ============================================
    echo.
    pause
    goto menu
)

echo.
echo ============================================
echo   Firestore indexes deployment complete!
echo ============================================
echo.
echo NOTE: Index building may take a few minutes.
echo The error will clear once indexes are ready.
echo.
pause
goto menu

:deploy_hosting_functions
echo.
echo ============================================
echo   Deploying Hosting + Functions...
echo ============================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Firebase CLI not found in PATH.
    echo Please install Firebase CLI: npm install -g firebase-tools
    echo.
    pause
    goto menu
)

echo Checking Firebase login status...
firebase projects:list 2>&1
set login_check=%ERRORLEVEL%
if %login_check% neq 0 (
    echo.
    echo ERROR: Not logged in to Firebase or authentication failed.
    echo.
    echo Please run: firebase login
    echo.
    pause
    goto menu
)

echo.
echo Login check passed!
echo.
echo Current Firebase project:
firebase use
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Failed to get current Firebase project.
    echo Please run: firebase use [project-id]
    echo.
    pause
    goto menu
)

echo.
set /p confirm="Deploy hosting and functions to this project? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Deployment cancelled.
    timeout /t 2 >nul
    goto menu
)

echo.
echo Deploying hosting and functions...
echo.
firebase deploy --only hosting,functions
set deploy_result=%ERRORLEVEL%

if %deploy_result% neq 0 (
    echo.
    echo ============================================
    echo ERROR: Deployment failed!
    echo Error code: %deploy_result%
    echo ============================================
    echo.
    pause
    goto menu
)

echo.
echo ============================================
echo   Hosting + Functions deployment complete!
echo ============================================
pause
goto menu

:end
echo.
echo Exiting...
timeout /t 1 >nul
exit /b 0
