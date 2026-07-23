param(
    [string]$Time = "12:45"
)

# Buat task harian memakai lokasi repository saat script ini dijalankan.
$RootDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$RunnerPath = Join-Path $RootDirectory "run_pipeline.bat"

schtasks.exe /create /tn "TV Guide ETL Pipeline" /tr "`"$RunnerPath`"" /sc DAILY /st $Time /it /f
