@echo off
REM 启动前后端服务的脚本
REM 包含导出PPT/PDF所需的所有环境变量

echo ==========================================
echo 启动 Presenton AI PPT 服务
echo ==========================================
echo.

REM 设置环境变量
set APP_DATA_DIRECTORY=C:\code\presenton-aippt\electron\app_data
set DISABLE_SSL_VERIFY=true
set HTTP_PROXY=http://secure-proxy2.qualcomm.com:9090
set HTTPS_PROXY=http://secure-proxy2.qualcomm.com:9090

echo [1/2] 启动前端服务 (Next.js)...
start "Next.js Frontend" cmd /k "cd electron\servers\nextjs && npx next dev -p 3000"
timeout /t 5 /nobreak > nul

echo [2/2] 启动后端服务 (FastAPI)...
start "FastAPI Backend" cmd /k "cd electron\servers\fastapi && uv run python server.py --port 8000"

echo.
echo ==========================================
echo 服务已启动！
echo ==========================================
echo 前端: http://localhost:3000
echo 后端: http://127.0.0.1:8000
echo.
echo 按任意键关闭此窗口...
pause > nul
