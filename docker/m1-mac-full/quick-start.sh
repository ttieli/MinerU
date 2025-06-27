#!/bin/bash

# MinerU M芯片全功能版快速启动脚本
# 这是一个简化版本，用于快速测试和验证修复方案

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# 主函数
main() {
    log_header "MinerU M芯片全功能版快速启动"
    
    # 1. 检查必要文件
    log_info "检查必要文件..."
    
    if [[ ! -f "Dockerfile.fixed" ]]; then
        log_error "Dockerfile.fixed 不存在"
        exit 1
    fi
    
    if [[ ! -f "docker-compose.fixed.yml" ]]; then
        log_error "docker-compose.fixed.yml 不存在"
        exit 1
    fi
    
    if [[ ! -f "build-fixed.sh" ]]; then
        log_error "build-fixed.sh 不存在"
        exit 1
    fi
    
    log_success "必要文件检查完成"
    
    # 2. 创建必要目录
    log_info "创建必要目录..."
    
    DIRS=(
        "./models"
        "./layoutreader"
        "./output"
        "./temp"
        "./config"
        "./logs"
        "./cache"
    )
    
    for dir in "${DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "创建目录: $dir"
        fi
    done
    
    # 3. 创建基础配置
    log_info "创建基础配置..."
    
    if [[ ! -f ".env" ]]; then
        cat > .env << 'EOF'
# MinerU M芯片全功能版配置
VERSION=2.0-full-fixed
API_PORT=8000
MONITOR_PORT=8080
DEVICE_MODE=mps
MPS_MEMORY_LIMIT=8G
MPS_MEMORY_FRACTION=0.8
ENABLE_VLM=true
ENABLE_PIPELINE=true
ENABLE_TABLE=true
ENABLE_FORMULA=true
MAX_WORKERS=4
BATCH_SIZE=2
MEMORY_LIMIT=16G
CPU_LIMIT=8.0
LOG_LEVEL=INFO
EOF
        log_success "创建了 .env 配置文件"
    fi
    
    # 4. 检查Docker
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose未安装"
        exit 1
    fi
    
    log_success "Docker环境检查完成"
    
    # 5. 构建镜像
    log_info "构建Docker镜像..."
    
    if docker build -f Dockerfile.fixed -t mineru-m1-full:latest .; then
        log_success "镜像构建成功"
    else
        log_error "镜像构建失败"
        exit 1
    fi
    
    # 6. 启动服务
    log_info "启动服务..."
    
    if docker-compose -f docker-compose.fixed.yml up -d; then
        log_success "服务启动成功"
    else
        log_error "服务启动失败"
        exit 1
    fi
    
    # 7. 等待服务就绪
    log_info "等待服务就绪..."
    sleep 10
    
    # 8. 检查服务状态
    log_info "检查服务状态..."
    docker-compose -f docker-compose.fixed.yml ps
    
    # 9. 显示访问信息
    log_header "服务启动完成"
    echo -e "${GREEN}🎉 MinerU M芯片全功能版已启动！${NC}"
    echo ""
    echo -e "${CYAN}📋 访问地址:${NC}"
    echo -e "  🔗 API服务:     ${BLUE}http://localhost:8000${NC}"
    echo -e "  📚 API文档:     ${BLUE}http://localhost:8000/docs${NC}"
    echo -e "  ❤️  健康检查:   ${BLUE}http://localhost:8000/health${NC}"
    echo ""
    echo -e "${CYAN}🛠️  管理命令:${NC}"
    echo -e "  查看日志:     ${YELLOW}docker-compose -f docker-compose.fixed.yml logs -f mineru-full${NC}"
    echo -e "  重启服务:     ${YELLOW}docker-compose -f docker-compose.fixed.yml restart mineru-full${NC}"
    echo -e "  停止服务:     ${YELLOW}docker-compose -f docker-compose.fixed.yml down${NC}"
    echo ""
    echo -e "${CYAN}📝 快速测试:${NC}"
    echo -e "  ${YELLOW}curl http://localhost:8000/health${NC}"
    
    # 10. 尝试健康检查
    log_info "尝试健康检查..."
    sleep 5
    
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        log_success "✅ 服务健康检查通过"
    else
        log_warning "⚠️  服务可能还在启动中，请稍后检查"
        echo -e "${YELLOW}可以使用以下命令查看日志：${NC}"
        echo -e "${YELLOW}docker-compose -f docker-compose.fixed.yml logs mineru-full${NC}"
    fi
}

# 错误处理
trap 'log_error "脚本执行出错，退出码: $?"' ERR

# 检查参数
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "MinerU M芯片全功能版快速启动脚本"
    echo ""
    echo "用法: $0"
    echo ""
    echo "这个脚本会自动执行以下操作："
    echo "1. 检查必要文件"
    echo "2. 创建必要目录"
    echo "3. 创建基础配置"
    echo "4. 检查Docker环境"
    echo "5. 构建Docker镜像"
    echo "6. 启动服务"
    echo "7. 验证服务状态"
    exit 0
fi

# 运行主函数
main "$@"