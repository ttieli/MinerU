#!/bin/bash

# MinerU Docker 统一启动脚本 - 苹果M芯片优化版
# 支持精简版和全功能版选择

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="MinerU Docker - M芯片优化版"
VERSION_LITE="lite"
VERSION_FULL="full"
DEFAULT_VERSION="lite"

echo -e "${BLUE}🚀 ${PROJECT_NAME}${NC}"
echo "=================================================="

# 显示版本选择信息
show_version_info() {
    echo -e "${CYAN}📊 可选版本：${NC}"
    echo ""
    echo -e "${GREEN}💡 精简版 (lite)${NC} - 推荐日常使用"
    echo -e "   • 内存需求：4GB（实际使用1-2GB）"
    echo -e "   • CPU模式运行，适合所有Mac设备"
    echo -e "   • 支持基础PDF解析、OCR识别"
    echo -e "   • 启动快速，资源占用低"
    echo ""
    echo -e "${BLUE}🚀 全功能版 (full)${NC} - 最强解析能力"  
    echo -e "   • 内存需求：16GB+（推荐32GB）"
    echo -e "   • 支持MPS加速，完整表格和公式识别"
    echo -e "   • 最高精度的文档解析"
    echo -e "   • 适合复杂文档和高质量要求"
    echo ""
}

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

# 选择版本
select_version() {
    local version=${1:-}
    
    if [[ -z "$version" ]]; then
        show_version_info
        echo -e "${YELLOW}请选择要启动的版本：${NC}"
        echo "  1) lite  - 精简版（推荐日常使用）"
        echo "  2) full  - 全功能版（最强解析能力）"
        echo ""
        read -p "请输入选择 [1-2，默认为1]: " choice
        
        case $choice in
            2|full)
                version="full"
                ;;
            1|lite|"")
                version="lite"
                ;;
            *)
                echo -e "${RED}❌ 无效选择，使用默认精简版${NC}"
                version="lite"
                ;;
        esac
    fi
    
    echo "$version"
}

# 获取版本配置
get_version_config() {
    local version=$1
    
    if [[ "$version" == "full" ]]; then
        DOCKER_DIR="docker/m1-mac-full"
        IMAGE_NAME="mineru-m1-full"
        CONTAINER_NAME="mineru-full-api"
        API_PORT="8008"
        MONITOR_PORT="8088"
        echo -e "${BLUE}🚀 选择：全功能版 - 最强解析能力${NC}"
    else
        DOCKER_DIR="docker/m1-mac"
        IMAGE_NAME="mineru-m1"
        CONTAINER_NAME="mineru-m1-api"
        API_PORT="8000"
        MONITOR_PORT="8080"
        echo -e "${GREEN}💡 选择：精简版 - 推荐日常使用${NC}"
    fi
}

# 构建镜像
build_image() {
    echo -e "${BLUE}🔨 构建Docker镜像...${NC}"
    
    if [[ ! -d "$DOCKER_DIR" ]]; then
        echo -e "${RED}❌ Docker配置目录不存在：$DOCKER_DIR${NC}"
        exit 1
    fi
    
    cd "$DOCKER_DIR"
    
    if [[ "$DOCKER_DIR" == "docker/m1-mac-full" ]]; then
        # 全功能版使用直接构建
        docker build -t ${IMAGE_NAME}:latest . || {
            echo -e "${RED}❌ 镜像构建失败${NC}"
            cd - > /dev/null
            exit 1
        }
    else
        # 精简版使用原有构建方式
        docker build -t ${IMAGE_NAME}:latest . || {
            echo -e "${RED}❌ 镜像构建失败${NC}"
            cd - > /dev/null
            exit 1
        }
    fi
    
    cd - > /dev/null
    echo -e "${GREEN}✅ 镜像构建完成${NC}"
}

# 启动服务
start_service() {
    echo -e "${BLUE}🎯 启动服务...${NC}"
    
    cd "$DOCKER_DIR"
    
    # 创建输出目录
    mkdir -p output temp
    
    if [[ "$DOCKER_DIR" == "docker/m1-mac-full" ]]; then
        # 全功能版使用简化启动
        ./simple_start.sh || {
            echo -e "${RED}❌ 服务启动失败${NC}"
            cd - > /dev/null
            exit 1
        }
    else
        # 精简版使用docker-compose
        docker-compose up -d || {
            echo -e "${RED}❌ 服务启动失败${NC}"
            cd - > /dev/null
            exit 1
        }
    fi
    
    cd - > /dev/null
    echo -e "${GREEN}✅ 服务启动成功${NC}"
}

# 等待服务就绪
wait_for_service() {
    echo -e "${BLUE}⏳ 等待服务就绪...${NC}"
    
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:${API_PORT}/health > /dev/null 2>&1; then
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
    local version_name
    if [[ "$DOCKER_DIR" == "docker/m1-mac-full" ]]; then
        version_name="全功能版"
    else
        version_name="精简版"
    fi
    
    echo -e "\n${GREEN}🎉 MinerU Docker ${version_name} 启动成功！${NC}"
    echo "=================================================="
    echo -e "📍 API服务:      ${BLUE}http://localhost:${API_PORT}${NC}"
    echo -e "📚 API文档:      ${BLUE}http://localhost:${API_PORT}/docs${NC}"
    echo -e "🏥 健康检查:     ${BLUE}http://localhost:${API_PORT}/health${NC}"
    echo -e "📁 输出目录:     ${BLUE}$(pwd)/${DOCKER_DIR}/output${NC}"
    
    if [[ "$DOCKER_DIR" == "docker/m1-mac-full" ]]; then
        echo -e "📊 监控端口:     ${BLUE}http://localhost:${MONITOR_PORT}${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}💡 使用示例:${NC}"
    echo -e "  上传文件解析:   ${BLUE}curl -X POST http://localhost:${API_PORT}/file_parse -F \"file=@document.pdf\"${NC}"
    echo ""
    echo -e "${YELLOW}🛠️  管理命令:${NC}"
    echo -e "  查看日志:       ${BLUE}$0 logs [lite|full]${NC}"
    echo -e "  停止服务:       ${BLUE}$0 stop [lite|full]${NC}"
    echo -e "  重启服务:       ${BLUE}$0 restart [lite|full]${NC}"
    echo -e "  查看状态:       ${BLUE}$0 status [lite|full]${NC}"
    echo -e "  运行测试:       ${BLUE}$0 test [lite|full]${NC}"
    echo -e "  清理资源:       ${BLUE}$0 clean [lite|full]${NC}"
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}🛑 停止服务...${NC}"
    
    if [[ "$DOCKER_DIR" == "docker/m1-mac-full" ]]; then
        # 停止全功能版
        docker stop mineru-full-standalone mineru-redis-standalone 2>/dev/null || true
        docker rm mineru-full-standalone mineru-redis-standalone 2>/dev/null || true
    else
        # 停止精简版
        cd "$DOCKER_DIR"
        docker-compose down
        cd - > /dev/null
    fi
    
    echo -e "${GREEN}✅ 服务已停止${NC}"
}

# 查看日志
show_logs() {
    echo -e "${BLUE}📋 查看服务日志...${NC}"
    
    if [[ "$DOCKER_DIR" == "docker/m1-mac-full" ]]; then
        echo -e "${CYAN}=== MinerU 全功能版日志 ===${NC}"
        docker logs -f mineru-full-standalone
    else
        cd "$DOCKER_DIR"
        docker-compose logs -f
        cd - > /dev/null
    fi
}

# 查看状态
show_status() {
    echo -e "${BLUE}📊 服务状态...${NC}"
    
    if [[ "$DOCKER_DIR" == "docker/m1-mac-full" ]]; then
        echo -e "${CYAN}=== 全功能版容器状态 ===${NC}"
        docker ps --filter "name=mineru-full" --filter "name=mineru-redis"
    else
        cd "$DOCKER_DIR"
        docker-compose ps
        cd - > /dev/null
    fi
    
    echo ""
    echo -e "${BLUE}🌐 API健康状态:${NC}"
    if curl -s http://localhost:${API_PORT}/health | python3 -m json.tool 2>/dev/null; then
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
        curl -s http://localhost:${API_PORT}/health | python3 -m json.tool
    fi
}

# 清理资源
clean_resources() {
    echo -e "${YELLOW}🧹 清理Docker资源...${NC}"
    
    if [[ "$DOCKER_DIR" == "docker/m1-mac-full" ]]; then
        docker stop mineru-full-standalone mineru-redis-standalone 2>/dev/null || true
        docker rm mineru-full-standalone mineru-redis-standalone 2>/dev/null || true
        docker rmi ${IMAGE_NAME}:latest 2>/dev/null || true
    else
        cd "$DOCKER_DIR"
        docker-compose down
        cd - > /dev/null
        docker rmi ${IMAGE_NAME}:latest 2>/dev/null || true
    fi
    
    docker system prune -f > /dev/null 2>&1 || true
    echo -e "${GREEN}✅ 清理完成${NC}"
}

# 显示帮助
show_help() {
    echo "MinerU Docker 启动脚本 - 苹果M芯片优化版"
    echo ""
    echo "使用方法: $0 [命令] [版本]"
    echo ""
    echo "版本选择:"
    echo "  lite      精简版 - 低内存占用，适合日常使用"
    echo "  full      全功能版 - 最强解析能力，适合复杂文档"
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
    echo "版本特性对比:"
    echo "  精简版特性:"
    echo "    • 内存需求: 4GB (实际使用1-2GB)"
    echo "    • CPU模式运行，无需GPU"
    echo "    • 支持基础PDF解析、OCR识别"
    echo "    • 启动快速，资源占用低"
    echo ""
    echo "  全功能版特性:"
    echo "    • 内存需求: 16GB+ (推荐32GB)"
    echo "    • 支持MPS加速，完整表格和公式识别"
    echo "    • 最高精度的文档解析"
    echo "    • 适合复杂文档和高质量要求"
    echo ""
    echo "示例:"
    echo "  $0                    # 交互式选择版本并启动"
    echo "  $0 start lite         # 启动精简版"
    echo "  $0 start full         # 启动全功能版"
    echo "  $0 logs full          # 查看全功能版日志"
    echo "  $0 stop lite          # 停止精简版"
}

# 主函数
main() {
    local command="${1:-start}"
    local version="${2:-}"
    
    case "$command" in
        "start")
            check_environment
            version=$(select_version "$version")
            get_version_config "$version"
            build_image
            start_service
            wait_for_service && show_service_info
            ;;
        "stop")
            if [[ -n "$version" ]]; then
                get_version_config "$version"
            else
                echo -e "${YELLOW}请指定要停止的版本：lite 或 full${NC}"
                exit 1
            fi
            stop_service
            ;;
        "restart")
            if [[ -n "$version" ]]; then
                get_version_config "$version"
            else
                echo -e "${YELLOW}请指定要重启的版本：lite 或 full${NC}"
                exit 1
            fi
            stop_service
            sleep 2
            start_service
            wait_for_service && show_service_info
            ;;
        "status")
            if [[ -n "$version" ]]; then
                get_version_config "$version"
            else
                echo "检查所有版本状态..."
                echo -e "${CYAN}=== 精简版状态 ===${NC}"
                get_version_config "lite"
                show_status 2>/dev/null || echo "精简版未运行"
                echo ""
                echo -e "${CYAN}=== 全功能版状态 ===${NC}"
                get_version_config "full"
                show_status 2>/dev/null || echo "全功能版未运行"
                return
            fi
            show_status
            ;;
        "logs")
            if [[ -n "$version" ]]; then
                get_version_config "$version"
            else
                echo -e "${YELLOW}请指定要查看日志的版本：lite 或 full${NC}"
                exit 1
            fi
            show_logs
            ;;
        "test")
            if [[ -n "$version" ]]; then
                get_version_config "$version"
            else
                echo -e "${YELLOW}请指定要测试的版本：lite 或 full${NC}"
                exit 1
            fi
            run_test
            ;;
        "build")
            check_environment
            version=$(select_version "$version")
            get_version_config "$version"
            build_image
            ;;
        "clean")
            if [[ -n "$version" ]]; then
                get_version_config "$version"
                clean_resources
            else
                echo -e "${YELLOW}清理所有版本的资源...${NC}"
                get_version_config "lite"
                clean_resources
                get_version_config "full"
                clean_resources
            fi
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $command${NC}"
            echo "使用 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
}

# 检查是否在正确的目录
if [[ ! -d "docker/m1-mac" ]]; then
    echo -e "${RED}❌ 请在MinerU项目根目录运行此脚本${NC}"
    echo "当前目录：$(pwd)"
    echo "期望目录包含：docker/m1-mac"
    exit 1
fi

# 执行主函数
main "$@"