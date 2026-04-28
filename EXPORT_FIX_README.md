# 服务启动和导出功能修复说明

## 问题说明
导出 PPT 和 PDF 功能失败的原因是缺少必要的环境变量配置。

## 解决方案
已经修复了以下内容：

### 1. 修改了 `electron/servers/fastapi/server.py`
自动设置导出功能所需的环境变量：
- `NEXT_PUBLIC_URL` - 前端URL
- `NEXT_PUBLIC_FAST_API` - 后端API URL
- `EXPORT_PACKAGE_ROOT` - 导出工具包路径

### 2. 创建了启动/停止脚本

#### 快速启动服务（推荐）
双击运行：
```
start-services.bat
```

这个脚本会：
- 自动设置所有必要的环境变量
- 启动前端服务（端口 3000）
- 启动后端服务（端口 8000）
- 在独立的命令行窗口中运行，方便查看日志

#### 停止服务
双击运行：
```
stop-services.bat
```

这个脚本会自动停止占用 3000 和 8000 端口的进程。

### 3. 手动启动（备选方案）

如果需要手动启动，使用以下命令：

**前端服务：**
```bash
cd electron/servers/nextjs
npx next dev -p 3000
```

**后端服务：**
```bash
cd electron/servers/fastapi
set APP_DATA_DIRECTORY=C:\code\presenton-aippt\electron\app_data
set DISABLE_SSL_VERIFY=true
set HTTP_PROXY=http://secure-proxy2.qualcomm.com:9090
set HTTPS_PROXY=http://secure-proxy2.qualcomm.com:9090
uv run python server.py --port 8000
```

## 重启服务以应用修复

由于当前服务正在运行，需要重启才能应用修复：

### 选项1：使用脚本（推荐）
1. 双击运行 `stop-services.bat` 停止当前服务
2. 双击运行 `start-services.bat` 重新启动服务

### 选项2：手动重启
1. 在任务管理器中结束 Node.js 和 Python 进程
2. 使用上面的启动脚本或手动命令重新启动

## 验证修复

重启服务后，导出功能应该可以正常工作了：
- 访问 http://localhost:3000
- 创建或打开一个演示文稿
- 点击导出按钮
- 选择 PDF 或 PPTX 格式
- 导出应该能成功完成

## 技术细节

修复内容包括：
1. 在 `server.py` 中添加了环境变量自动配置
2. 自动检测并设置 `presentation-export` 目录路径
3. 确保前端URL和后端API URL正确配置

如有任何问题，请查看服务的日志输出。
