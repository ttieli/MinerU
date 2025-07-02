#!/bin/bash

# MinerU Apple Silicon Docker 一键启动脚本
# 支持M1/M2/M3/M4芯片的简化版和完整版选择

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 图标定义
INFO="ℹ️"
SUCCESS="✅"
WARNING="⚠️"
ERROR="❌"
ROCKET="🚀"
GEAR="⚙️"
CHIP="💻"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

print_success() {
    echo -e "${GREEN}${SUCCESS} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_error() {
    echo -e "${RED}${ERROR} $1${NC}"
}

print_title() {
    echo -e "${PURPLE}${ROCKET} $1${NC}"
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    __  __ _                 _   _ 
   |  \/  (_)_ __   ___ _ __| | | |
   | |\/| | | '_ \ / _ \ '__| | | |
   | |  | | | | | |  __/ |  | |_| |
   |_|  |_|_|_| |_|\___|_|   \___/ 
                                   
   Apple Silicon Docker 一键启动脚本
EOF
    echo -e "${NC}"
    echo -e "${WHITE}支持 M1/M2/M3/M4 芯片的完整版和简化版选择${NC}"
    echo ""
}

# 检查系统架构
check_architecture() {
    print_info "检查系统架构..."
    
    ARCH=$(uname -m)
    OS=$(uname -s)
    
    if [[ "$OS" != "Darwin" ]]; then
        print_error "此脚本仅支持 macOS 系统"
        exit 1
    fi
    
    if [[ "$ARCH" != "arm64" ]]; then
        print_error "此脚本仅支持 Apple Silicon (ARM64) 芯片"
        print_info "当前架构: $ARCH"
        print_info "如果您使用的是 Intel Mac，请使用 x86_64 版本"
        exit 1
    fi
    
    print_success "检测到 Apple Silicon 芯片 ($ARCH)"
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖..."
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装"
        print_info "请先安装 Docker Desktop for Mac: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    
    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        print_error "Docker 未运行"
        print_info "请启动 Docker Desktop 后重试"
        exit 1
    fi
    
    # 检查 Docker Compose (优先使用新版 docker compose)
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        print_success "检测到 Docker Compose v2，使用 docker compose"
        DOCKER_COMPOSE="docker compose"
    elif command -v docker-compose &> /dev/null; then
        print_warning "使用旧版 docker-compose，建议升级到 Docker Desktop 最新版"
        DOCKER_COMPOSE="docker-compose"
    else
        print_error "未找到 Docker Compose，请确认 Docker Desktop 已正确安装"
        exit 1
    fi
    
    print_success "所有依赖检查通过"
}

# 检查系统资源
check_resources() {
    print_info "检查系统资源..."
    
    # 获取内存信息 (GB)
    TOTAL_MEMORY=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    
    # 获取可用磁盘空间 (GB)
    AVAILABLE_DISK=$(df -g . | awk 'NR==2 {print $4}')
    
    print_info "总内存: ${TOTAL_MEMORY}GB"
    print_info "可用磁盘空间: ${AVAILABLE_DISK}GB"
    
    # 资源建议
    if [[ $TOTAL_MEMORY -lt 8 ]]; then
        print_warning "内存不足 8GB，建议只使用简化版"
        RESOURCE_RECOMMENDATION="light"
    elif [[ $TOTAL_MEMORY -lt 16 ]]; then
        print_warning "内存少于 16GB，建议使用简化版，完整版可能运行缓慢"
        RESOURCE_RECOMMENDATION="light"
    else
        print_success "内存充足，可以运行完整版"
        RESOURCE_RECOMMENDATION="both"
    fi
    
    if [[ $AVAILABLE_DISK -lt 10 ]]; then
        print_error "磁盘空间不足 10GB，无法运行"
        exit 1
    elif [[ $AVAILABLE_DISK -lt 20 ]]; then
        print_warning "磁盘空间较少，建议清理空间或使用简化版"
    fi
}

# 选择版本
select_version() {
    print_title "选择 MinerU 版本"
    echo ""
    echo -e "${GREEN}1)${NC} 简化版 (推荐用于日常使用)"
    echo -e "   ${GRAY}• 内存占用: 4GB"
    echo -e "   • 功能: PDF基础解析、OCR、API服务"
    echo -e "   • 适用: 日常文档处理、低配置设备${NC}"
    echo ""
    echo -e "${BLUE}2)${NC} 完整版 (推荐用于专业使用)"
    echo -e "   ${GRAY}• 内存占用: 16GB+"
    echo -e "   • 功能: VLM多模态、表格识别、公式识别、WebUI"
    echo -e "   • 适用: 专业文档分析、高精度需求${NC}"
    echo ""
    
    # 根据资源情况给出建议
    if [[ "$RESOURCE_RECOMMENDATION" == "light" ]]; then
        echo -e "${YELLOW}📊 根据您的系统资源，建议选择简化版${NC}"
    fi
    echo ""
    
    while true; do
        read -p "请选择版本 (1-2): " choice
        case $choice in
            1)
                VERSION="light"
                VERSION_NAME="简化版"
                DOCKER_DIR="docker/m1-mac"
                DOCKER_COMPOSE_FILE="docker-compose.yml"
                API_PORT="8000"
                break
                ;;
            2)
                VERSION="full"
                VERSION_NAME="完整版"
                DOCKER_DIR="docker/m1-mac-full"
                DOCKER_COMPOSE_FILE="docker-compose-fixed.yml"
                API_PORT="8001"
                if [[ $TOTAL_MEMORY -lt 16 ]]; then
                    echo ""
                    print_warning "您的内存可能不足以流畅运行完整版"
                    read -p "是否继续? (y/N): " confirm
                    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                        continue
                    fi
                fi
                break
                ;;
            *)
                print_error "无效选择，请输入 1 或 2"
                ;;
        esac
    done
    
    print_success "已选择: $VERSION_NAME"
}

# 配置环境变量
configure_environment() {
    print_info "配置环境变量..."
    
    # 创建 .env 文件
    ENV_FILE="$DOCKER_DIR/.env"
    
    cat > "$ENV_FILE" << EOF
# MinerU $VERSION_NAME 环境配置
# 生成时间: $(date)

# 版本信息
VERSION=latest
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# 端口配置 (根据版本动态设置)
API_PORT=${API_PORT:-8000}
WEBUI_PORT=${WEBUI_PORT:-3000}
MONITOR_PORT=8080
HTTP_PORT=80
HTTPS_PORT=443

# 模型源配置 (huggingface/modelscope)
MINERU_MODEL_SOURCE=huggingface

# 资源配置
MEMORY_LIMIT=${TOTAL_MEMORY}G
MEMORY_RESERVATION=$((TOTAL_MEMORY/2))G
CPU_LIMIT=8.0
CPU_RESERVATION=4.0

EOF

    if [[ "$VERSION" == "full" ]]; then
        cat >> "$ENV_FILE" << EOF
# 完整版特定配置
API_PORT=8001
WEBUI_PORT=3001
DEVICE_MODE=mps
MPS_MEMORY_LIMIT=8G
MPS_MEMORY_FRACTION=0.8

# 功能开关
ENABLE_VLM=true
ENABLE_PIPELINE=true
ENABLE_TABLE=true
ENABLE_FORMULA=true
ENABLE_LLM_AIDED=false
ENABLE_WEBUI=false

# 性能配置
MAX_WORKERS=4
BATCH_SIZE=2
MODEL_PRECISION=fp16
WORKER_PROCESSES=4
WORKER_THREADS=2
QUEUE_MAX_SIZE=100
REQUEST_TIMEOUT=300

# 内存优化
MEMORY_EFFICIENT_MODE=true
MODEL_OFFLOAD_CPU=true
CLEAR_CACHE_INTERVAL=100
ADAPTIVE_BATCH_SIZE=true
MAX_CONCURRENT_REQUESTS=4

# 监控配置
GRAFANA_PASSWORD=admin123

EOF
    fi
    
    print_success "环境配置完成"
}

# 询问高级选项
ask_advanced_options() {
    echo ""
    read -p "是否配置高级选项? (y/N): " advanced
    
    if [[ "$advanced" =~ ^[Yy]$ ]]; then
        echo ""
        print_title "高级配置选项"
        
        # WebUI选项
        if [[ "$VERSION" == "full" ]]; then
            echo ""
            read -p "是否启用 WebUI 界面? (y/N): " enable_webui
            if [[ "$enable_webui" =~ ^[Yy]$ ]]; then
                sed -i '' 's/ENABLE_WEBUI=false/ENABLE_WEBUI=true/' "$ENV_FILE"
                ENABLE_WEBUI=true
            fi
        fi
        
        # 端口配置
        echo ""
        current_port=$(grep "API_PORT=" "$ENV_FILE" | tail -1 | cut -d'=' -f2)
        read -p "是否自定义 API 端口? (当前: $current_port, 直接回车跳过): " custom_port
        if [[ -n "$custom_port" ]]; then
            sed -i '' "s/API_PORT=$current_port/API_PORT=$custom_port/" "$ENV_FILE"
        fi
        
        # 模型源选择
        echo ""
        echo "选择模型源:"
        echo "1) HuggingFace (默认)"
        echo "2) ModelScope (国内用户推荐)"
        read -p "请选择 (1-2, 默认1): " model_source
        if [[ "$model_source" == "2" ]]; then
            sed -i '' 's/MINERU_MODEL_SOURCE=huggingface/MINERU_MODEL_SOURCE=modelscope/' "$ENV_FILE"
        fi
    fi
}

# 启动服务
start_services() {
    print_title "启动 MinerU $VERSION_NAME"
    
    print_info "拉取/构建镜像 (使用 --no-cache 确保应用最新代码)..."
    $DOCKER_COMPOSE -f $DOCKER_DIR/$DOCKER_COMPOSE_FILE build --no-cache
    print_info "启动服务..."
    $DOCKER_COMPOSE -f $DOCKER_DIR/$DOCKER_COMPOSE_FILE up -d
    # 如果启用了WebUI，启动WebUI服务
    if [[ "$VERSION" == "full" && "$ENABLE_WEBUI" == "true" ]]; then
        $DOCKER_COMPOSE -f $DOCKER_DIR/$DOCKER_COMPOSE_FILE --profile webui up -d
    fi
    print_success "服务启动成功!"
}

# 等待服务就绪
wait_for_services() {
    print_info "等待服务启动..."
    local max_attempts=30
    local attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        current_api_port=$(grep "API_PORT=" "$ENV_FILE" | tail -1 | cut -d'=' -f2)
        if curl -s http://localhost:$current_api_port/health &> /dev/null; then
            print_success "API 服务就绪!"
            break
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    if [[ $attempt -eq $max_attempts ]]; then
        print_warning "服务启动超时，请检查日志"
        $DOCKER_COMPOSE -f $DOCKER_DIR/$DOCKER_COMPOSE_FILE logs --tail=10
        return 1
    fi
}

# 显示访问信息
show_access_info() {
    print_title "服务访问信息"
    echo ""
    API_PORT=$(grep "API_PORT=" "$ENV_FILE" | cut -d'=' -f2)
    print_success "API 服务: http://localhost:$API_PORT"
    print_info "API 文档: http://localhost:$API_PORT/docs"
    print_info "健康检查: http://localhost:$API_PORT/health"
    if [[ "$VERSION" == "full" && "$ENABLE_WEBUI" == "true" ]]; then
        WEBUI_PORT=$(grep "WEBUI_PORT=" "$ENV_FILE" | cut -d'=' -f2)
        print_success "WebUI 界面: http://localhost:$WEBUI_PORT"
    fi
    echo ""
    print_info "常用命令:"
    echo -e "  ${CYAN}# 查看服务状态${NC}"
    echo -e "  $DOCKER_COMPOSE -f $DOCKER_DIR/$DOCKER_COMPOSE_FILE ps"
    echo ""
    echo -e "  ${CYAN}# 查看日志${NC}"
    echo -e "  $DOCKER_COMPOSE -f $DOCKER_DIR/$DOCKER_COMPOSE_FILE logs -f"
    echo ""
    echo -e "  ${CYAN}# 停止服务${NC}"
    echo -e "  $DOCKER_COMPOSE -f $DOCKER_DIR/$DOCKER_COMPOSE_FILE down"
    echo ""
    echo -e "  ${CYAN}# 重启服务${NC}"
    echo -e "  $DOCKER_COMPOSE -f $DOCKER_DIR/$DOCKER_COMPOSE_FILE restart"
}

# 快速测试
quick_test() {
    echo ""
    read -p "是否进行快速 API 测试? (y/N): " test_api
    
    if [[ "$test_api" =~ ^[Yy]$ ]]; then
        print_info "执行 API 测试..."
        
        # 健康检查测试
        current_api_port=$(grep "API_PORT=" "$ENV_FILE" | tail -1 | cut -d'=' -f2)
        if curl -s http://localhost:$current_api_port/health | grep -q "healthy"; then
            print_success "健康检查通过"
        else
            print_warning "健康检查失败"
        fi
        
        # API 端点测试
        if curl -s http://localhost:$current_api_port/docs &> /dev/null; then
            print_success "API 文档可访问"
        else
            print_warning "API 文档无法访问"
        fi
    fi
}

# 清理函数
cleanup() {
    if [[ $? -ne 0 ]]; then
        print_error "启动过程中出现错误"
        print_info "查看日志以获取更多信息:"
        echo "  $DOCKER_COMPOSE -f $DOCKER_DIR/$DOCKER_COMPOSE_FILE logs"
    fi
}

# 主函数
main() {
    # 设置错误处理
    trap cleanup EXIT
    
    # 显示欢迎信息
    show_welcome
    
    # 系统检查
    check_architecture
    check_dependencies
    check_resources
    
    # 用户选择
    select_version
    
    # 配置环境
    configure_environment
    ask_advanced_options
    
    # 启动服务
    start_services
    wait_for_services
    
    # 显示信息
    show_access_info
    quick_test
    
    echo ""
    print_success "MinerU $VERSION_NAME 启动完成! $ROCKET"
    print_info "享受高效的文档解析体验！"
}

# 检查是否在项目根目录
if [[ ! -d "docker" ]]; then
    print_error "请在 MinerU 项目根目录运行此脚本"
    exit 1
fi

# 运行主函数
main "$@" 