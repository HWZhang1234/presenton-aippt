#!/bin/bash

# Navigate to FastAPI directory
cd "$(dirname "$0")/electron/servers/fastapi"

# Set environment variables
export APP_DATA_DIRECTORY='C:\code\presenton-aippt\electron\app_data'
export DISABLE_SSL_VERIFY='true'
export HTTP_PROXY='http://secure-proxy2.qualcomm.com:9090'
export HTTPS_PROXY='http://secure-proxy2.qualcomm.com:9090'
export NEXT_PUBLIC_URL='http://localhost:3000'
export NEXT_PUBLIC_FASTAPI_URL='http://127.0.0.1:8000'
export FASTAPI_PUBLIC_URL='http://127.0.0.1:8000'
export EXPORT_PACKAGE_ROOT='C:\code\presenton-aippt\presentation-export'

# Start FastAPI server
python -m uvicorn server:app --reload --host 0.0.0.0 --port 8000
