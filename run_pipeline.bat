@echo off
REM
cd /d "%~dp0"

if not exist logs mkdir logs

REM
echo [%date% %time%] Pipeline started >> logs\schedule.log
"C:\Users\LENOVO\anaconda3\envs\lab\python.exe" main.py >> logs\schedule.log 2>&1

if errorlevel 1 (
    echo [%date% %time%] Pipeline failed with exit code %errorlevel% >> logs\schedule.log
    exit /b %errorlevel%
)

echo [%date% %time%] Pipeline completed successfully >> logs\schedule.log
