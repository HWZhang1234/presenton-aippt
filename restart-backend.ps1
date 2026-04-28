# PowerShell script to restart backend with correct environment variables

Write-Host "Stopping old backend processes..." -ForegroundColor Yellow

# Stop all Python processes on port 8000
$processes = netstat -ano | Select-String ":8000.*LISTENING" | ForEach-Object {
    $_.Line -split '\s+' | Select-Object -Last 1
} | Sort-Object -Unique

foreach ($pid in $processes) {
    if ($pid -and $pid -ne "0") {
        Write-Host "Killing process PID: $pid"
        taskkill /F /PID $pid 2>$null
    }
}

Start-Sleep -Seconds 2

Write-Host "Starting backend with correct configuration..." -ForegroundColor Green

# Navigate to FastAPI directory
Set-Location "$PSScriptRoot\electron\servers\fastapi"

# Set environment variables for the session
$env:APP_DATA_DIRECTORY = "C:\code\presenton-aippt\electron\app_data"
$env:DISABLE_SSL_VERIFY = "true"
$env:HTTP_PROXY = "http://secure-proxy2.qualcomm.com:9090"
$env:HTTPS_PROXY = "http://secure-proxy2.qualcomm.com:9090"
$env:NEXT_PUBLIC_URL = "http://localhost:3000"
$env:EXPORT_PACKAGE_ROOT = "C:\code\presenton-aippt\presentation-export"

# Start backend using server.py (which sets FASTAPI_PUBLIC_URL internally)
Write-Host "Backend starting on http://127.0.0.1:8000" -ForegroundColor Cyan
python server.py --port 8000 --reload true
