@echo off
REM
cd /d "%~dp0"

if not exist logs mkdir logs

REM
set "PYTHON_EXE=%~dp0.venv\Scripts\python.exe"

if not exist "%PYTHON_EXE%" (
    echo [%date% %time%] Virtual environment tidak ditemukan. >> logs\schedule.log
    exit /b 1
)

echo [%date% %time%] Pipeline started >> logs\schedule.log
"%PYTHON_EXE%" main.py >> logs\schedule.log 2>&1

if errorlevel 1 (
    echo [%date% %time%] Pipeline failed with exit code %errorlevel% >> logs\schedule.log
    exit /b %errorlevel%
)

echo [%date% %time%] Pipeline completed successfully >> logs\schedule.log
