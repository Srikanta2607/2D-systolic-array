@echo off
REM ============================================================================
REM  PYNQ-Z2 Systolic Array Accelerator – Vivado 2026.1 Launcher
REM  Double-click or run from command prompt
REM ============================================================================

set VIVADO_EXE=C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%pynq_z2_optimized_vivado_2026_1\
set TCL_SCRIPT=%PROJECT_DIR%vivado\run_all.tcl
set BUILD_DIR=%PROJECT_DIR%vivado_build

echo ============================================================
echo  PYNQ-Z2 Systolic Array Accelerator
echo  Vivado 2026.1 - Full Flow (Synth + Sim + Impl)
echo  DSP: 64 per engine (128 total, power optimized)
echo ============================================================

if not exist "%VIVADO_EXE%" (
    echo ERROR: Vivado not found at: %VIVADO_EXE%
    echo Please check your Vivado installation.
    pause
    exit /b 1
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo Starting Vivado batch run...
echo Log: %BUILD_DIR%\vivado_run.log
echo.

"%VIVADO_EXE%" -mode batch -source "%TCL_SCRIPT%" -log "%BUILD_DIR%\vivado_run.log" -journal "%BUILD_DIR%\vivado_run.jou"

if errorlevel 1 (
    echo.
    echo *** FLOW FAILED - check log: %BUILD_DIR%\vivado_run.log
    pause
    exit /b 1
)

echo.
echo *** FLOW COMPLETE - Reports in: %PROJECT_DIR%reports\
pause
