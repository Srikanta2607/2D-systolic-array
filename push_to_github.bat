@echo off
cd /d "%~dp0"
title Push Latest Work to GitHub (Srikanta2607)
echo ============================================================
echo   Pushing Optimized 2D Systolic Array to GitHub
echo ============================================================
echo.
echo Target Account : Srikanta2607
echo Repository     : https://github.com/Srikanta2607/2D-systolic-array.git
echo Branch         : main
echo.
echo If prompted by Git Credential Manager, click "Sign in with your browser"
echo to complete authentication with your GitHub account.
echo.
git push -u origin main
echo.
if %errorlevel% equ 0 (
    echo ============================================================
    echo   SUCCESS! All latest work uploaded successfully!
    echo   View online: https://github.com/Srikanta2607/2D-systolic-array
    echo ============================================================
) else (
    echo ============================================================
    echo   Push failed or was cancelled. Please check network/login.
    echo ============================================================
)
echo.
pause
