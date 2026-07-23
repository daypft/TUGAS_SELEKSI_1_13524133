param(
    [string]$Time = "12:45"
)

$RootDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$RunnerPath = Join-Path $RootDirectory "run_pipeline.bat"

schtasks.exe /create /tn "TV Guide ETL Pipeline" /tr "`"$RunnerPath`"" /sc DAILY /st $Time /it /f
