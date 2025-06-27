#!/bin/bash

# MinerU全功能版启动脚本（包含所有模型）

echo "🚀 启动MinerU全功能版"
echo "====================="
echo "✅ 包含所有下载的模型 (2.4GB)"
echo "✅ 针对48GB内存优化配置"
echo "✅ 支持表格和公式识别"
echo ""

# 检查端口
if lsof -i :8008 >/dev/null 2>&1; then
    echo "❌ 端口8008已被占用"
    exit 1
fi

# 创建输出目录
mkdir -p /tmp/mineru_full/{output,temp,cache,logs}

echo "🔧 启动配置："
echo "   - 镜像大小: 8.56GB (包含模型)"
echo "   - 内存限制: 16GB"
echo "   - CPU限制: 8核"
echo "   - 工作进程: 6个"
echo "   - 批处理: 3个文档"
echo "   - 端口: 8008"
echo ""

echo "📦 启动容器..."
docker run -d \
    --name mineru-full-api \
    --restart unless-stopped \
    -p 8008:8000 \
    -p 8088:8080 \
    -e PYTHONPATH=/app \
    -e LOG_LEVEL=INFO \
    -e DEVICE_MODE=mps \
    -e MPS_MEMORY_LIMIT=12G \
    -e MPS_MEMORY_FRACTION=0.8 \
    -e MAX_WORKERS=6 \
    -e BATCH_SIZE=3 \
    -e ENABLE_VLM=true \
    -e ENABLE_PIPELINE=true \
    -e ENABLE_TABLE=true \
    -e ENABLE_FORMULA=true \
    -e MEMORY_EFFICIENT_MODE=false \
    -e MODEL_OFFLOAD_CPU=false \
    -e CLEAR_CACHE_INTERVAL=200 \
    -e ADAPTIVE_BATCH_SIZE=true \
    -e MODEL_PRECISION=fp16 \
    -e REQUEST_TIMEOUT=600 \
    -e MAX_CONCURRENT_REQUESTS=6 \
    -v /tmp/mineru_full/output:/app/output \
    -v /tmp/mineru_full/temp:/app/temp \
    -v /tmp/mineru_full/cache:/app/cache \
    -v /tmp/mineru_full/logs:/app/logs \
    --memory=16g \
    --cpus=8 \
    --shm-size=4g \
    mineru-enhanced:latest

echo "⏳ 等待服务启动..."
sleep 20

# 健康检查
echo "🔍 服务状态检查..."
for i in {1..30}; do
    if curl -s http://localhost:8008/health >/dev/null 2>&1; then
        echo "✅ MinerU全功能版启动成功！"
        echo ""
        echo "🌐 服务信息："
        echo "   - API地址: http://localhost:8008"
        echo "   - 健康检查: http://localhost:8008/health"
        echo "   - API文档: http://localhost:8008/docs"
        echo "   - 监控端口: http://localhost:8088"
        echo ""
        echo "🎯 功能特性："
        echo "   ✅ 完整PDF解析"
        echo "   ✅ 多语言OCR"
        echo "   ✅ 表格识别和提取"
        echo "   ✅ 数学公式识别"
        echo "   ✅ 智能布局分析"
        echo "   ✅ 阅读顺序检测"
        echo "   ✅ 高精度输出"
        echo ""
        echo "📊 容器状态："
        docker ps --filter "name=mineru-full-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo "📝 使用示例："
        echo "curl -X POST http://localhost:8008/api/v1/parse \\"
        echo "     -F 'file=@your_document.pdf' \\"
        echo "     -F 'mode=full' \\"
        echo "     -F 'enable_table=true' \\"
        echo "     -F 'enable_formula=true'"
        echo ""
        echo "💡 提示: 使用 ./monitor_resources.sh 监控资源使用"
        exit 0
    fi
    echo "等待中... ($i/30)"
    sleep 5
done

echo "❌ 服务启动超时，请检查日志："
echo "docker logs mineru-full-api"

