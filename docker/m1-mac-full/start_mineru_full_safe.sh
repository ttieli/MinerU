#!/bin/bash

# MinerU全功能版安全启动脚本
# 确保不影响现有Docker服务

set -e

echo "🚀 正在启动MinerU全功能版..."
echo "📊 配置信息："
echo "   - API端口: 8008"
echo "   - 监控端口: 8088" 
echo "   - 内存限制: 16GB"
echo "   - 工作进程: 6个"
echo ""

# 检查端口冲突
echo "🔍 检查端口占用情况..."
if lsof -i :8008 >/dev/null 2>&1; then
    echo "❌ 端口8008已被占用，请检查！"
    exit 1
fi

if lsof -i :8088 >/dev/null 2>&1; then
    echo "❌ 端口8088已被占用，请检查！"
    exit 1
fi

echo "✅ 端口检查通过"

# 检查Docker是否运行
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker未运行，请启动Docker"
    exit 1
fi

echo "✅ Docker状态正常"

# 显示当前运行的容器
echo ""
echo "📋 当前运行的容器："
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}" | head -10

echo ""
echo "🔧 使用生产环境配置启动MinerU全功能版..."

# 使用生产环境配置启动
docker-compose --env-file .env.production up -d mineru-full redis

echo ""
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "📊 服务状态检查："
docker-compose --env-file .env.production ps

echo ""
echo "🔍 健康检查..."
for i in {1..30}; do
    if curl -s http://localhost:8008/health >/dev/null 2>&1; then
        echo "✅ MinerU全功能版启动成功！"
        echo ""
        echo "🌐 访问地址："
        echo "   - API: http://localhost:8008"
        echo "   - 健康检查: http://localhost:8008/health"
        echo "   - API文档: http://localhost:8008/docs"
        echo "   - 监控: http://localhost:8088"
        echo ""
        echo "📚 使用示例："
        echo "   curl -X POST http://localhost:8008/api/v1/parse \\"
        echo "        -F 'file=@your_document.pdf' \\"
        echo "        -F 'mode=full'"
        echo ""
        exit 0
    fi
    echo "等待中... ($i/30)"
    sleep 5
done

echo "❌ 服务启动超时，请检查日志："
echo "docker-compose --env-file .env.production logs mineru-full"

