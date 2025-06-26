#!/bin/bash

# MinerU M1 Mac Docker 快速启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="MinerU M1 Mac"
IMAGE_NAME="mineru-m1"
CONTAINER_NAME="mineru-m1-api"

echo -e "${BLUE}🚀 ${PROJECT_NAME} Docker 快速启动${NC}"
echo "=================================="

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker未运行或未安装${NC}"
    echo "请确保Docker Desktop正在运行"
    exit 1
fi

# 检查架构
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo -e "${YELLOW}⚠️  检测到非ARM64架构: $ARCH${NC}"
    echo "此配置专为M1/M2 Mac优化，可能在其他架构上性能不佳"
fi

# 函数：构建镜像
build_image() {
    echo -e "${BLUE}🔨 构建Docker镜像...${NC}"
    docker build -t ${IMAGE_NAME}:latest . || {
        echo -e "${RED}❌ 镜像构建失败${NC}"
        exit 1
    }
    echo -e "${GREEN}✅ 镜像构建完成${NC}"
}

# 函数：启动服务
start_service() {
    echo -e "${BLUE}🎯 启动服务...${NC}"
    
    # 停止已存在的容器
    if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}⚠️  停止已存在的容器${NC}"
        docker stop ${CONTAINER_NAME} > /dev/null 2>&1 || true
        docker rm ${CONTAINER_NAME} > /dev/null 2>&1 || true
    fi
    
    # 创建输出目录
    mkdir -p output
    
    # 启动容器
    docker run -d \
        --name ${CONTAINER_NAME} \
        --platform linux/arm64 \
        -p 8000:8000 \
        -v "$(pwd)/output:/app/output" \
        -e MINERU_MODEL_SOURCE=huggingface \
        -e TORCH_NUM_THREADS=4 \
        -e OMP_NUM_THREADS=4 \
        --memory=4g \
        --cpus=2.0 \
        ${IMAGE_NAME}:latest || {
        echo -e "${RED}❌ 容器启动失败${NC}"
        exit 1
    }
    
    echo -e "${GREEN}✅ 容器启动成功${NC}"
}

# 函数：等待服务就绪
wait_for_service() {
    echo -e "${BLUE}⏳ 等待服务就绪...${NC}"
    
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 服务已就绪${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 5
        ((attempt++))
    done
    
    echo -e "\n${RED}❌ 服务启动超时${NC}"
    echo "请检查容器日志: docker logs ${CONTAINER_NAME}"
    return 1
}

# 函数：显示服务信息
show_service_info() {
    echo -e "\n${GREEN}🎉 服务启动成功！${NC}"
    echo "=================================="
    echo -e "📍 API地址:     ${BLUE}http://localhost:8000${NC}"
    echo -e "📚 API文档:     ${BLUE}http://localhost:8000/docs${NC}"
    echo -e "🏥 健康检查:    ${BLUE}http://localhost:8000/health${NC}"
    echo -e "📁 输出目录:    ${BLUE}$(pwd)/output${NC}"
    echo ""
    echo "常用命令:"
    echo -e "  查看日志:     ${YELLOW}docker logs -f ${CONTAINER_NAME}${NC}"
    echo -e "  停止服务:     ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
    echo -e "  重启服务:     ${YELLOW}docker restart ${CONTAINER_NAME}${NC}"
    echo -e "  进入容器:     ${YELLOW}docker exec -it ${CONTAINER_NAME} bash${NC}"
    echo -e "  运行测试:     ${YELLOW}python test_api.py${NC}"
}

# 函数：显示帮助
show_help() {
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  build     构建Docker镜像"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  logs      查看日志"
    echo "  test      运行测试"
    echo "  status    查看状态"
    echo "  clean     清理资源"
    echo "  help      显示帮助"
    echo ""
    echo "示例:"
    echo "  $0         # 完整启动（构建+启动）"
    echo "  $0 build   # 只构建镜像"
    echo "  $0 start   # 只启动服务"
}

# 主函数
main() {
    case "${1:-}" in
        "build")
            build_image
            ;;
        "start")
            start_service
            wait_for_service && show_service_info
            ;;
        "stop")
            echo -e "${YELLOW}🛑 停止服务...${NC}"
            docker stop ${CONTAINER_NAME} > /dev/null 2>&1 || true
            echo -e "${GREEN}✅ 服务已停止${NC}"
            ;;
        "restart")
            echo -e "${YELLOW}🔄 重启服务...${NC}"
            docker restart ${CONTAINER_NAME} > /dev/null 2>&1 || {
                echo -e "${RED}❌ 重启失败，尝试重新启动${NC}"
                start_service
            }
            wait_for_service && show_service_info
            ;;
        "logs")
            echo -e "${BLUE}📋 查看日志...${NC}"
            docker logs -f ${CONTAINER_NAME}
            ;;
        "test")
            echo -e "${BLUE}🧪 运行测试...${NC}"
            python test_api.py
            ;;
        "status")
            echo -e "${BLUE}📊 服务状态...${NC}"
            docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            echo ""
            curl -s http://localhost:8000/health | python -m json.tool 2>/dev/null || echo "服务未响应"
            ;;
        "clean")
            echo -e "${YELLOW}🧹 清理资源...${NC}"
            docker stop ${CONTAINER_NAME} > /dev/null 2>&1 || true
            docker rm ${CONTAINER_NAME} > /dev/null 2>&1 || true
            docker rmi ${IMAGE_NAME}:latest > /dev/null 2>&1 || true
            echo -e "${GREEN}✅ 清理完成${NC}"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            # 默认完整启动
            build_image
            start_service
            wait_for_service && show_service_info
            ;;
        *)
            echo -e "${RED}❌ 未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"