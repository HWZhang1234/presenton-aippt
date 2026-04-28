@echo off
REM 停止前后端服务的脚本

echo ==========================================
echo 停止 Presenton AI PPT 服务
echo ==========================================
echo.

echo 正在查找并停止服务...

REM 停止占用 3000 端口的进程 (Next.js)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
    echo 停止前端服务 (PID: %%a)...
    taskkill /F /PID %%a 2>nul
)

REM 停止占用 8000 端口的进程 (FastAPI)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000 ^| findstr LISTENING') do (
    echo 停止后端服务 (PID: %%a)...
    taskkill /F /PID %%a 2>nul
)

echo.
echo ==========================================
echo 服务已停止！
echo ==========================================
echo.
pause
