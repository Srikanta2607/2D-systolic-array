@echo off
REM ============================================================================
REM  Quick launcher for Synthesis Only (faster than full flow)
REM ============================================================================

set VIVADO_EXE=C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%pynq_z2_optimized_vivado_2026_1\
set TCL_SCRIPT=%PROJECT_DIR%vivado\run_synthesis.tcl
set BUILD_DIR=%PROJECT_DIR%vivado_build

echo ============================================================
echo  PYNQ-Z2 Systolic Array - SYNTHESIS ONLY
echo ============================================================

if not exist "%VIVADO_EXE%" (
    echo ERROR: Vivado not found at: %VIVADO_EXE%
    pause
    exit /b 1
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

"%VIVADO_EXE%" -mode batch -source "%TCL_SCRIPT%" -log "%BUILD_DIR%\synth.log" -journal "%BUILD_DIR%\synth.jou"
if errorlevel 1 (
    echo SYNTHESIS FAILED
    pause
    exit /b 1
)

echo SYNTHESIS COMPLETE - See %PROJECT_DIR%reports\vivado_synth\
pause
