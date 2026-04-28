#!/bin/bash

echo "Stopping old backend processes..."

# Get all PIDs listening on port 8000
pids=$(netstat -ano | grep ":8000.*LISTENING" | awk '{print $5}' | sort -u)

# Kill each process
for pid in $pids; do
    if [ ! -z "$pid" ] && [ "$pid" != "0" ]; then
        echo "Killing process PID: $pid"
        taskkill //F //PID $pid 2>/dev/null || true
    fi
done

sleep 2

echo "Starting backend with correct configuration..."

# Navigate to FastAPI directory
cd "$(dirname "$0")/electron/servers/fastapi"

# Set environment variables
export APP_DATA_DIRECTORY='C:\code\presenton-aippt\electron\app_data'
export DISABLE_SSL_VERIFY='true'
export HTTP_PROXY='http://secure-proxy2.qualcomm.com:9090'
export HTTPS_PROXY='http://secure-proxy2.qualcomm.com:9090'
export NEXT_PUBLIC_URL='http://localhost:3000'
export EXPORT_PACKAGE_ROOT='C:\code\presenton-aippt\presentation-export'

# Start backend using server.py (which sets FASTAPI_PUBLIC_URL internally)
echo "Backend starting on http://127.0.0.1:8000"
python server.py --port 8000 --reload true
