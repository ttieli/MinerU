#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}MinerU M1 Mac Docker Container Starting...${NC}"

# 检查模型目录
if [ ! -d "/opt/models" ] || [ -z "$(ls -A /opt/models)" ]; then
    echo -e "${YELLOW}Models directory is empty, downloading core models...${NC}"
    python download_models_light.py
fi

# 设置环境变量
export MINERU_MODEL_SOURCE=${MINERU_MODEL_SOURCE:-huggingface}
export PYTHONPATH=/app:$PYTHONPATH

# 检查配置文件
if [ ! -f "/root/magic-pdf.json" ]; then
    echo -e "${RED}Configuration file not found!${NC}"
    exit 1
fi

echo -e "${GREEN}Configuration loaded from /root/magic-pdf.json${NC}"

# 启动健康检查端点
cat > /app/health_check.py << 'EOF'
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
import threading
import time

health_app = FastAPI()

@health_app.get("/health")
async def health_check():
    return JSONResponse({"status": "healthy", "service": "mineru-m1"})

def run_health_server():
    uvicorn.run(health_app, host="0.0.0.0", port=8001, log_level="error")

if __name__ == "__main__":
    run_health_server()
EOF

# 在后台启动健康检查服务
python /app/health_check.py &

# 启动主应用
echo -e "${GREEN}Starting MinerU API Server...${NC}"
echo -e "${YELLOW}Access the API at: http://localhost:8000${NC}"
echo -e "${YELLOW}API Documentation: http://localhost:8000/docs${NC}"

exec uvicorn app:app "$@"