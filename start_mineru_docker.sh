#!/bin/bash

# MinerU Docker 统一启动脚本 - 苹果M芯片优化版
# 适用于 M1/M2/M3/M4 芯片的 Mac 设备

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="MinerU Docker - M芯片优化版"
IMAGE_NAME="mineru-m1"
CONTAINER_NAME="mineru-m1-api"
DOCKER_DIR="docker/m1-mac"

echo -e "${BLUE}🚀 ${PROJECT_NAME}${NC}"
echo "=================================================="

# 检查系统环境
check_environment() {
    echo -e "${BLUE}🔍 检查系统环境...${NC}"
    
    # 检查操作系统
    if [[ "$(uname)" != "Darwin" ]]; then
        echo -e "${YELLOW}⚠️  此脚本为 macOS 优化，当前系统：$(uname)${NC}"
    fi
    
    # 检查架构
    ARCH=$(uname -m)
    if [[ "$ARCH" != "arm64" ]]; then
        echo -e "${YELLOW}⚠️  此配置专为M芯片优化，当前架构：$ARCH${NC}"
    else
        echo -e "${GREEN}✅ 检测到 Apple Silicon 架构${NC}"
    fi
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker未安装，请先安装 Docker Desktop${NC}"
        echo "下载地址：https://www.docker.com/products/docker-desktop/"
        exit 1
    fi
    
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker未运行，请启动 Docker Desktop${NC}"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Docker Compose未安装${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 环境检查完成${NC}"
}

# 构建镜像
build_image() {
    echo -e "${BLUE}🔨 构建Docker镜像...${NC}"
    
    if [[ ! -d "$DOCKER_DIR" ]]; then
        echo -e "${RED}❌ Docker配置目录不存在：$DOCKER_DIR${NC}"
        exit 1
    fi
    
    cd "$DOCKER_DIR"
    docker build -t ${IMAGE_NAME}:latest . || {
        echo -e "${RED}❌ 镜像构建失败${NC}"
        cd - > /dev/null
        exit 1
    }
    cd - > /dev/null
    
    echo -e "${GREEN}✅ 镜像构建完成${NC}"
}

# 启动服务
start_service() {
    echo -e "${BLUE}🎯 启动服务...${NC}"
    
    cd "$DOCKER_DIR"
    
    # 创建输出目录
    mkdir -p output
    
    # 使用docker-compose启动
    docker-compose up -d || {
        echo -e "${RED}❌ 服务启动失败${NC}"
        cd - > /dev/null
        exit 1
    }
    
    cd - > /dev/null
    echo -e "${GREEN}✅ 服务启动成功${NC}"
}

# 等待服务就绪
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

# 显示服务信息
show_service_info() {
    echo -e "\n${GREEN}🎉 MinerU Docker 服务启动成功！${NC}"
    echo "=================================================="
    echo -e "📍 API服务:      ${BLUE}http://localhost:8000${NC}"
    echo -e "📚 API文档:      ${BLUE}http://localhost:8000/docs${NC}"
    echo -e "🏥 健康检查:     ${BLUE}http://localhost:8000/health${NC}"
    echo -e "📁 输出目录:     ${BLUE}$(pwd)/${DOCKER_DIR}/output${NC}"
    echo ""
    echo -e "${YELLOW}💡 使用示例:${NC}"
    echo -e "  上传文件解析:   ${BLUE}curl -X POST http://localhost:8000/file_parse -F \"file=@document.pdf\"${NC}"
    echo ""
    echo -e "${YELLOW}🛠️  管理命令:${NC}"
    echo -e "  查看日志:       ${BLUE}$0 logs${NC}"
    echo -e "  停止服务:       ${BLUE}$0 stop${NC}"
    echo -e "  重启服务:       ${BLUE}$0 restart${NC}"
    echo -e "  查看状态:       ${BLUE}$0 status${NC}"
    echo -e "  运行测试:       ${BLUE}$0 test${NC}"
    echo -e "  清理资源:       ${BLUE}$0 clean${NC}"
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}🛑 停止服务...${NC}"
    cd "$DOCKER_DIR"
    docker-compose down
    cd - > /dev/null
    echo -e "${GREEN}✅ 服务已停止${NC}"
}

# 查看日志
show_logs() {
    echo -e "${BLUE}📋 查看服务日志...${NC}"
    cd "$DOCKER_DIR"
    docker-compose logs -f
    cd - > /dev/null
}

# 查看状态
show_status() {
    echo -e "${BLUE}📊 服务状态...${NC}"
    cd "$DOCKER_DIR"
    docker-compose ps
    cd - > /dev/null
    
    echo ""
    echo -e "${BLUE}🌐 API健康状态:${NC}"
    if curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null; then
        echo -e "${GREEN}✅ API服务正常${NC}"
    else
        echo -e "${RED}❌ API服务异常${NC}"
    fi
}

# 运行测试
run_test() {
    echo -e "${BLUE}🧪 运行API测试...${NC}"
    
    if [[ -f "${DOCKER_DIR}/test_api.py" ]]; then
        cd "$DOCKER_DIR"
        python3 test_api.py
        cd - > /dev/null
    else
        echo -e "${YELLOW}⚠️  测试脚本不存在，运行基础健康检查${NC}"
        curl -s http://localhost:8000/health | python3 -m json.tool
    fi
}

# 清理资源
clean_resources() {
    echo -e "${YELLOW}🧹 清理Docker资源...${NC}"
    cd "$DOCKER_DIR"
    docker-compose down
    cd - > /dev/null
    
    docker rmi ${IMAGE_NAME}:latest 2>/dev/null || true
    docker system prune -f > /dev/null 2>&1 || true
    
    echo -e "${GREEN}✅ 清理完成${NC}"
}

# 显示帮助
show_help() {
    echo "MinerU Docker 启动脚本 - 苹果M芯片优化版"
    echo ""
    echo "使用方法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start     启动服务（默认：构建+启动）"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  status    查看服务状态"
    echo "  logs      查看服务日志"
    echo "  test      运行API测试"
    echo "  build     仅构建镜像"
    echo "  clean     清理所有资源"
    echo "  help      显示帮助信息"
    echo ""
    echo "特性:"
    echo "  • 专为苹果M芯片（M1/M2/M3/M4）优化"
    echo "  • 低内存占用（4GB限制，实际使用1-2GB）"
    echo "  • CPU模式运行，无需GPU"
    echo "  • 完整的PDF/Office文档解析功能"
    echo "  • RESTful API接口"
    echo ""
    echo "示例:"
    echo "  $0              # 完整启动"
    echo "  $0 start        # 启动服务"
    echo "  $0 logs         # 查看日志"
    echo "  $0 test         # 测试API"
}

# 主函数
main() {
    case "${1:-start}" in
        "start")
            check_environment
            build_image
            start_service
            wait_for_service && show_service_info
            ;;
        "stop")
            stop_service
            ;;
        "restart")
            stop_service
            sleep 2
            start_service
            wait_for_service && show_service_info
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "test")
            run_test
            ;;
        "build")
            check_environment
            build_image
            ;;
        "clean")
            clean_resources
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            echo "使用 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
}

# 检查是否在正确的目录
if [[ ! -d "$DOCKER_DIR" ]]; then
    echo -e "${RED}❌ 请在MinerU项目根目录运行此脚本${NC}"
    echo "当前目录：$(pwd)"
    echo "期望目录包含：$DOCKER_DIR"
    exit 1
fi

# 执行主函数
main "$@"