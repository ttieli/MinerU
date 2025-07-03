#!/bin/bash
# MinerU 统一启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo -e "${BLUE}MinerU Docker 统一启动脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  simple     - 启动Simple版本 (8000端口)"
    echo "  full       - 启动Full版本 (8001端口)"
    echo "  both       - 启动两个版本 (默认)"
    echo "  stop       - 停止所有服务"
    echo "  restart    - 重启所有服务"
    echo "  logs       - 查看日志"
    echo "  status     - 查看状态"
    echo "  clean      - 清理容器和镜像"
    echo "  help       - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 both         # 启动两个版本"
    echo "  $0 simple       # 只启动简化版"
    echo "  $0 full         # 只启动完整版"
    echo "  $0 logs simple  # 查看简化版日志"
}

# 检查Docker是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker未运行或无权限访问${NC}"
        echo "请启动Docker Desktop或检查权限设置"
        exit 1
    fi
}

# 设置环境变量
set_env() {
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    export COMPOSE_PROJECT_NAME=mineru
}

# 启动服务
start_service() {
    local service=$1
    
    echo -e "${BLUE}🚀 启动 MinerU $service 版本...${NC}"
    
    case $service in
        "simple")
            docker-compose up -d mineru-simple
            echo -e "${GREEN}✅ Simple版本已启动 (端口: 8000)${NC}"
            ;;
        "full")
            docker-compose up -d mineru-full
            echo -e "${GREEN}✅ Full版本已启动 (端口: 8001)${NC}"
            ;;
        "both")
            docker-compose up -d mineru-simple mineru-full
            echo -e "${GREEN}✅ 两个版本都已启动${NC}"
            echo -e "${GREEN}   - Simple版本: http://localhost:8000${NC}"
            echo -e "${GREEN}   - Full版本: http://localhost:8001${NC}"
            ;;
    esac
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}🛑 停止所有MinerU服务...${NC}"
    docker-compose down
    echo -e "${GREEN}✅ 服务已停止${NC}"
}

# 重启服务
restart_service() {
    echo -e "${YELLOW}🔄 重启MinerU服务...${NC}"
    docker-compose down
    docker-compose up -d mineru-simple mineru-full
    echo -e "${GREEN}✅ 服务已重启${NC}"
}

# 查看日志
show_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo -e "${BLUE}📋 查看所有服务日志...${NC}"
        docker-compose logs -f
    else
        echo -e "${BLUE}📋 查看 $service 服务日志...${NC}"
        docker-compose logs -f mineru-$service
    fi
}

# 查看状态
show_status() {
    echo -e "${BLUE}📊 MinerU 服务状态:${NC}"
    echo ""
    
    # 检查容器状态
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "mineru-(simple|full)"; then
        echo ""
        echo -e "${BLUE}🔍 健康检查:${NC}"
        
        # 检查Simple版本
        if docker ps | grep -q "mineru-simple"; then
            if curl -s http://localhost:8000/health > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Simple版本 (8000): 健康${NC}"
            else
                echo -e "${RED}❌ Simple版本 (8000): 不健康${NC}"
            fi
        fi
        
        # 检查Full版本
        if docker ps | grep -q "mineru-full"; then
            if curl -s http://localhost:8001/health > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Full版本 (8001): 健康${NC}"
            else
                echo -e "${RED}❌ Full版本 (8001): 不健康${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  没有运行中的MinerU容器${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}💾 磁盘使用情况:${NC}"
    docker system df | grep -E "(TYPE|TOTAL)"
}

# 清理资源
clean_resources() {
    echo -e "${YELLOW}🧹 清理MinerU资源...${NC}"
    
    # 停止并删除容器
    docker-compose down --remove-orphans
    
    # 删除未使用的镜像
    docker image prune -f
    
    # 删除未使用的卷（可选）
    read -p "是否删除数据卷？这将清除所有模型和缓存 (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down -v
        echo -e "${GREEN}✅ 数据卷已清理${NC}"
    fi
    
    echo -e "${GREEN}✅ 资源清理完成${NC}"
}

# 主函数
main() {
    # 切换到脚本目录
    cd "$(dirname "$0")"
    
    # 检查Docker
    check_docker
    
    # 设置环境
    set_env
    
    # 处理命令
    case ${1:-both} in
        "simple"|"full"|"both")
            start_service $1
            ;;
        "stop")
            stop_service
            ;;
        "restart")
            restart_service
            ;;
        "logs")
            show_logs $2
            ;;
        "status")
            show_status
            ;;
        "clean")
            clean_resources
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知选项: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"