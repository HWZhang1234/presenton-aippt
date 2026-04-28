# PowerShell 脚本：重启 Presenton AI PPT 服务
Write-Host "=========================================="
Write-Host "重启 Presenton AI PPT 服务"
Write-Host "=========================================="
Write-Host ""

# 停止占用 3000 端口的进程
Write-Host "[1/4] 停止前端服务 (端口 3000)..."
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($port3000) {
    foreach ($pid in $port3000) {
        Write-Host "  - 停止进程 PID: $pid"
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  ✓ 前端服务已停止"
} else {
    Write-Host "  - 没有找到运行的前端服务"
}

Start-Sleep -Seconds 2

# 停止占用 8000 端口的进程
Write-Host "[2/4] 停止后端服务 (端口 8000)..."
$port8000 = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($port8000) {
    foreach ($pid in $port8000) {
        Write-Host "  - 停止进程 PID: $pid"
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  ✓ 后端服务已停止"
} else {
    Write-Host "  - 没有找到运行的后端服务"
}

Start-Sleep -Seconds 3

# 设置环境变量
$env:APP_DATA_DIRECTORY = "C:\code\presenton-aippt\electron\app_data"
$env:DISABLE_SSL_VERIFY = "true"
$env:HTTP_PROXY = "http://secure-proxy2.qualcomm.com:9090"
$env:HTTPS_PROXY = "http://secure-proxy2.qualcomm.com:9090"

# 启动前端服务
Write-Host "[3/4] 启动前端服务..."
$frontendPath = "C:\code\presenton-aippt\electron\servers\nextjs"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$frontendPath'; npx next dev -p 3000" -WindowStyle Normal
Write-Host "  ✓ 前端服务启动命令已执行"

Start-Sleep -Seconds 5

# 启动后端服务
Write-Host "[4/4] 启动后端服务（包含导出修复）..."
$backendPath = "C:\code\presenton-aippt\electron\servers\fastapi"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; uv run python server.py --port 8000" -WindowStyle Normal
Write-Host "  ✓ 后端服务启动命令已执行"

Write-Host ""
Write-Host "=========================================="
Write-Host "服务正在启动中..."
Write-Host "=========================================="
Write-Host "请等待约 30 秒让服务完全启动"
Write-Host ""
Write-Host "前端: http://localhost:3000"
Write-Host "后端: http://127.0.0.1:8000"
Write-Host ""
Write-Host "服务启动后，导出功能应该可以正常工作了！"
Write-Host ""
Write-Host "按任意键关闭此窗口..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
