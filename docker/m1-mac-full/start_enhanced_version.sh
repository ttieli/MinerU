#!/bin/bash

# 基于现有镜像启动增强版MinerU
# 通过配置优化来提供更好的功能

echo "🚀 启动MinerU增强版（基于现有镜像优化）"
echo "================================================"

# 检查端口
if lsof -i :8008 >/dev/null 2>&1; then
    echo "❌ 端口8008已被占用"
    exit 1
fi

# 创建必要的目录
mkdir -p /tmp/mineru_enhanced/{output,temp,models,cache}

echo "📦 启动增强版MinerU..."
docker run -d \
    --name mineru-enhanced \
    --restart unless-stopped \
    -p 8008:8000 \
    -e PYTHONPATH=/app \
    -e LOG_LEVEL=INFO \
    -e DEVICE_MODE=mps \
    -e MPS_MEMORY_LIMIT=12G \
    -e MAX_WORKERS=6 \
    -e BATCH_SIZE=3 \
    -e ENABLE_TABLE=true \
    -e ENABLE_FORMULA=true \
    -e MEMORY_EFFICIENT_MODE=false \
    -e MODEL_PRECISION=fp16 \
    -v /tmp/mineru_enhanced/output:/app/output \
    -v /tmp/mineru_enhanced/temp:/app/temp \
    -v /tmp/mineru_enhanced/models:/app/models \
    -v /tmp/mineru_enhanced/cache:/app/cache \
    --memory=12g \
    --cpus=6 \
    --shm-size=2g \
    mineru_simple-mineru-api:latest

echo "⏳ 等待服务启动..."
sleep 15

# 健康检查
if curl -s http://localhost:8008/health >/dev/null 2>&1; then
    echo "✅ MinerU增强版启动成功！"
    echo ""
    echo "🌐 访问信息："
    echo "   - API地址: http://localhost:8008"
    echo "   - 健康检查: http://localhost:8008/health"
    echo "   - API文档: http://localhost:8008/docs"
    echo ""
    echo "⚙️ 配置特点："
    echo "   - 内存限制: 12GB"
    echo "   - 工作进程: 6个"
    echo "   - 批处理: 3个文档"
    echo "   - MPS加速: 启用"
    echo "   - 表格识别: 启用"
    echo "   - 公式识别: 启用"
    echo ""
    echo "📊 容器状态："
    docker ps --filter "name=mineru-enhanced" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "📝 使用示例："
    echo "curl -X POST http://localhost:8008/api/v1/parse \\"
    echo "     -F 'file=@your_document.pdf' \\"
    echo "     -F 'enable_table=true' \\"
    echo "     -F 'enable_formula=true'"
else
    echo "❌ 服务启动失败，检查日志："
    echo "docker logs mineru-enhanced"
fi

