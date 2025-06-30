#!/bin/bash

# 简化启动脚本 - 避免复杂配置问题

echo "🚀 启动MinerU全功能版（简化模式）..."

# 检查端口
if lsof -i :8008 >/dev/null 2>&1; then
    echo "❌ 端口8008已被占用"
    exit 1
fi

# 清理可能的网络冲突
docker network prune -f >/dev/null 2>&1

# 先启动Redis（使用独立的Redis）
echo "📦 启动Redis..."
docker run -d \
    --name mineru-redis-standalone \
    --restart unless-stopped \
    -p 127.0.0.1:6380:6379 \
    redis:7-alpine \
    redis-server --appendonly yes --maxmemory 512mb --maxmemory-policy allkeys-lru

sleep 3

# 直接运行MinerU容器（如果镜像存在）
if docker images | grep -q "mineru-m1-full"; then
    echo "🎯 启动MinerU全功能版..."
    docker run -d \
        --name mineru-full-standalone \
        --restart unless-stopped \
        -p 8008:8000 \
        -p 8088:8080 \
        -e DEVICE_MODE=mps \
        -e MPS_MEMORY_LIMIT=12G \
        -e MEMORY_LIMIT=16G \
        -e MAX_WORKERS=6 \
        -e BATCH_SIZE=3 \
        -e ENABLE_VLM=true \
        -e ENABLE_PIPELINE=true \
        -e ENABLE_TABLE=true \
        -e ENABLE_FORMULA=true \
        -e MEMORY_EFFICIENT_MODE=true \
        -e MODEL_OFFLOAD_CPU=true \
        -e REDIS_HOST=host.docker.internal \
        -e REDIS_PORT=6380 \
        --add-host=host.docker.internal:host-gateway \
        -v $(pwd)/output:/app/output \
        -v $(pwd)/temp:/app/temp \
        mineru-m1-full:latest
else
    echo "⚠️  镜像不存在，需要先构建..."
    echo "正在构建MinerU全功能版镜像..."
    docker build -t mineru-m1-full:latest .
    
    if [ $? -eq 0 ]; then
        echo "✅ 构建成功，启动服务..."
        exec $0  # 重新执行脚本
    else
        echo "❌ 构建失败"
        exit 1
    fi
fi

echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
if curl -s http://localhost:8008/health >/dev/null 2>&1; then
    echo "✅ MinerU全功能版启动成功！"
    echo ""
    echo "🌐 访问地址："
    echo "   - API: http://localhost:8008"
    echo "   - 健康检查: http://localhost:8008/health"
    echo "   - API文档: http://localhost:8008/docs"
    echo ""
    echo "📊 容器状态："
    docker ps --filter "name=mineru" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "❌ 服务启动失败，检查日志："
    echo "docker logs mineru-full-standalone"
fi

