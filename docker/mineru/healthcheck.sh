#!/bin/bash
# MinerU 健康检查脚本

set -e

# 检查服务是否响应
if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ 服务健康检查通过"
    exit 0
else
    echo "❌ 服务健康检查失败"
    exit 1
fi