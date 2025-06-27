#!/bin/bash

# MinerU安全启动脚本
# 可以选择启动简化版或全功能版

set -e

echo "🚀 MinerU Docker 启动助手"
echo "=========================="
echo ""
echo "检测到以下MinerU镜像："
docker images | grep mineru || echo "   无MinerU镜像"
echo ""

# 检查当前运行的MinerU容器
RUNNING_MINERU=$(docker ps --filter "name=mineru" --format "{{.Names}}" | head -5)
if [ ! -z "$RUNNING_MINERU" ]; then
    echo "⚠️  当前已有MinerU容器运行："
    echo "$RUNNING_MINERU"
    echo ""
    read -p "是否要停止现有容器并启动新的？(y/N): " STOP_EXISTING
    if [[ $STOP_EXISTING =~ ^[Yy]$ ]]; then
        echo "🛑 停止现有容器..."
        echo "$RUNNING_MINERU" | xargs -I {} docker stop {} 2>/dev/null || true
        echo "$RUNNING_MINERU" | xargs -I {} docker rm {} 2>/dev/null || true
    else
        echo "保持现有容器运行"
        exit 0
    fi
fi

echo "请选择要启动的版本："
echo "1) 简化版 (已有镜像，快速启动)"
echo "2) 全功能版 (需要构建，功能完整)"
echo "3) 查看当前运行状态"
echo ""
read -p "请输入选择 (1-3): " CHOICE

case $CHOICE in
    1)
        echo "🎯 启动简化版..."
        
        # 检查端口
        if lsof -i :8008 >/dev/null 2>&1; then
            echo "❌ 端口8008已被占用，使用8009端口"
            API_PORT=8009
        else
            API_PORT=8008
        fi
        
        # 启动简化版
        docker run -d \
            --name mineru-simple-api \
            --restart unless-stopped \
            -p ${API_PORT}:8000 \
            -e PYTHONPATH=/app \
            -v $(pwd)/output:/app/output \
            -v $(pwd)/temp:/app/temp \
            mineru_simple-mineru-api:latest
        
        echo "⏳ 等待服务启动..."
        sleep 10
        
        # 健康检查
        if curl -s http://localhost:${API_PORT}/health >/dev/null 2>&1; then
            echo "✅ 简化版启动成功！"
            echo ""
            echo "🌐 访问地址："
            echo "   - API: http://localhost:${API_PORT}"
            echo "   - 健康检查: http://localhost:${API_PORT}/health"
            echo "   - API文档: http://localhost:${API_PORT}/docs"
            echo ""
            echo "📝 特性说明："
            echo "   - 轻量级版本，内存占用约2-4GB"
            echo "   - 支持基础PDF解析和OCR"
            echo "   - 不支持表格和公式识别"
            echo "   - 适合日常文档处理"
        else
            echo "❌ 服务启动失败，检查日志："
            echo "docker logs mineru-simple-api"
        fi
        ;;
        
    2)
        echo "🔧 准备启动全功能版..."
        echo "⚠️  注意：全功能版需要更多资源和时间"
        
        cd ../m1-mac-full
        
        # 检查是否需要构建
        if ! docker images | grep -q "mineru-m1-full"; then
            echo "📦 需要先构建全功能版镜像..."
            echo "这可能需要10-30分钟，请耐心等待..."
            
            # 尝试构建
            if docker build -t mineru-m1-full:latest .; then
                echo "✅ 构建成功"
            else
                echo "❌ 构建失败，可能是网络问题"
                echo "建议稍后重试或使用简化版"
                exit 1
            fi
        fi
        
        # 启动全功能版
        ./simple_start.sh
        ;;
        
    3)
        echo "📊 当前Docker状态："
        echo ""
        echo "🐳 所有运行的容器："
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | head -15
        echo ""
        echo "🎯 MinerU相关容器："
        docker ps --filter "name=mineru" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" || echo "   无MinerU容器运行"
        echo ""
        echo "💾 MinerU镜像："
        docker images | grep mineru || echo "   无MinerU镜像"
        echo ""
        echo "🔍 端口占用检查："
        echo "   8008: $(lsof -i :8008 >/dev/null 2>&1 && echo '占用' || echo '空闲')"
        echo "   8009: $(lsof -i :8009 >/dev/null 2>&1 && echo '占用' || echo '空闲')"
        echo "   8000: $(lsof -i :8000 >/dev/null 2>&1 && echo '占用' || echo '空闲')"
        ;;
        
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

