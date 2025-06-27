#!/bin/bash

# MinerU M芯片全功能版快速构建脚本
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 版本信息
VERSION="2.0-full"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# 日志函数
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

# 显示帮助信息
show_help() {
    echo "MinerU M芯片全功能版构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示此帮助信息"
    echo "  -b, --build-only        仅构建镜像，不启动服务"
    echo "  -s, --start-only        仅启动服务（需要已构建的镜像）"
    echo "  -c, --clean             清理现有镜像和容器"
    echo "  -p, --pull-latest       拉取最新基础镜像"
    echo "  -d, --dev               开发模式（挂载源代码）"
    echo "  -m, --models-cache DIR  指定模型缓存目录"
    echo "  -w, --webui             启用WebUI界面"
    echo "  -M, --monitoring        启用监控服务"
    echo "  --no-predownload        构建时不预下载模型"
    echo "  --source SOURCE         模型源 (huggingface|modelscope)"
    echo ""
    echo "示例:"
    echo "  $0                      # 完整构建并启动"
    echo "  $0 -b                   # 仅构建镜像"
    echo "  $0 -s                   # 仅启动服务"
    echo "  $0 -w -M               # 启动包含WebUI和监控"
    echo "  $0 -d                   # 开发模式"
    echo "  $0 --source modelscope  # 使用ModelScope源"
}

# 检查系统要求
check_requirements() {
    log_header "检查系统要求"
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker Desktop"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose未安装"
        exit 1
    fi
    
    # 检查架构
    ARCH=$(uname -m)
    if [[ "$ARCH" != "arm64" ]]; then
        log_warning "当前架构为 $ARCH，此镜像专为 ARM64 (Apple Silicon) 优化"
        read -p "是否继续？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # 检查内存
    if [[ "$OSTYPE" == "darwin"* ]]; then
        MEMORY_GB=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
        if [[ $MEMORY_GB -lt 16 ]]; then
            log_warning "检测到内存为 ${MEMORY_GB}GB，推荐至少16GB内存"
        else
            log_success "检测到内存: ${MEMORY_GB}GB"
        fi
    fi
    
    # 检查磁盘空间
    AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G.*//')
    if [[ $AVAILABLE_SPACE -lt 20 ]]; then
        log_warning "可用磁盘空间不足20GB，可能影响模型下载"
    fi
    
    log_success "系统要求检查完成"
}

# 清理现有资源
clean_resources() {
    log_header "清理现有资源"
    
    log_info "停止现有容器..."
    docker-compose down --remove-orphans 2>/dev/null || true
    
    log_info "删除现有镜像..."
    docker rmi mineru-m1-full:latest 2>/dev/null || true
    docker rmi mineru-m1-full:$VERSION 2>/dev/null || true
    
    log_info "清理未使用的资源..."
    docker system prune -f
    
    log_success "资源清理完成"
}

# 拉取最新基础镜像
pull_base_images() {
    log_header "拉取最新基础镜像"
    
    log_info "拉取Python基础镜像..."
    docker pull python:3.11-slim
    
    log_info "拉取其他服务镜像..."
    docker pull redis:7-alpine
    docker pull nginx:alpine
    
    log_success "基础镜像拉取完成"
}

# 构建镜像
build_image() {
    log_header "构建MinerU全功能镜像"
    
    # 设置构建参数
    BUILD_ARGS=(
        --build-arg BUILD_DATE="$BUILD_DATE"
        --build-arg VERSION="$VERSION"
        --platform linux/arm64
    )
    
    # 模型预下载配置
    if [[ "$NO_PREDOWNLOAD" == "true" ]]; then
        BUILD_ARGS+=(--build-arg PREDOWNLOAD_MODELS=false)
        log_info "禁用构建时模型预下载"
    else
        BUILD_ARGS+=(--build-arg PREDOWNLOAD_MODELS=true)
        log_info "启用构建时模型预下载"
    fi
    
    log_info "开始构建镜像..."
    log_info "构建参数: ${BUILD_ARGS[*]}"
    
    # 执行构建
    if docker build "${BUILD_ARGS[@]}" -t mineru-m1-full:$VERSION -t mineru-m1-full:latest .; then
        log_success "✅ 镜像构建成功！"
        
        # 显示镜像信息
        log_info "镜像信息:"
        docker images mineru-m1-full:latest --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    else
        log_error "❌ 镜像构建失败！"
        exit 1
    fi
}

# 创建环境配置
create_env_file() {
    log_info "创建环境配置文件..."
    
    # 生成.env文件
    cat > .env << EOF
# MinerU M芯片全功能版配置
VERSION=$VERSION
BUILD_DATE=$BUILD_DATE

# 模型源配置
MINERU_MODEL_SOURCE=${MODEL_SOURCE:-huggingface}

# 端口配置
API_PORT=8000
WEBUI_PORT=3000
MONITOR_PORT=8080
HTTP_PORT=80
HTTPS_PORT=443

# 设备配置
DEVICE_MODE=mps
MPS_MEMORY_LIMIT=8G
MPS_MEMORY_FRACTION=0.8

# 功能开关
ENABLE_VLM=true
ENABLE_PIPELINE=true
ENABLE_TABLE=true
ENABLE_FORMULA=true
ENABLE_LLM_AIDED=false
ENABLE_WEBUI=${ENABLE_WEBUI:-false}

# 性能配置
MAX_WORKERS=4
BATCH_SIZE=2
MEMORY_LIMIT=16G
CPU_LIMIT=8.0
MEMORY_RESERVATION=8G
CPU_RESERVATION=4.0

# 优化配置
MEMORY_EFFICIENT_MODE=true
MODEL_OFFLOAD_CPU=true
CLEAR_CACHE_INTERVAL=100
ADAPTIVE_BATCH_SIZE=true
MAX_CONCURRENT_REQUESTS=4

# 模型路径配置
MODELS_PATH=${MODELS_CACHE:-./models}

# 日志配置
LOG_LEVEL=INFO
LOG_FORMAT=json

# 监控配置
GRAFANA_PASSWORD=admin123
EOF
    
    log_success "环境配置文件已创建: .env"
}

# 创建必要目录
create_directories() {
    log_info "创建必要目录..."
    
    DIRS=(
        "./output"
        "./temp" 
        "./config"
        "./plugins"
        "./logs"
        "${MODELS_CACHE:-./models}"
    )
    
    for dir in "${DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "创建目录: $dir"
        fi
    done
    
    log_success "目录创建完成"
}

# 启动服务
start_services() {
    log_header "启动MinerU服务"
    
    # 创建配置
    create_env_file
    create_directories
    
    # 确定启动配置
    COMPOSE_PROFILES=()
    
    if [[ "$ENABLE_WEBUI" == "true" ]]; then
        COMPOSE_PROFILES+=(webui)
        log_info "启用WebUI界面"
    fi
    
    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        COMPOSE_PROFILES+=(monitoring)
        log_info "启用监控服务"
    fi
    
    if [[ "$DEV_MODE" == "true" ]]; then
        COMPOSE_FILE="docker-compose.yml:docker-compose.dev.yml"
        log_info "启用开发模式"
    else
        COMPOSE_FILE="docker-compose.yml"
    fi
    
    # 构建启动命令
    START_CMD="docker-compose"
    
    if [[ ${#COMPOSE_PROFILES[@]} -gt 0 ]]; then
        for profile in "${COMPOSE_PROFILES[@]}"; do
            START_CMD+=" --profile $profile"
        done
    fi
    
    START_CMD+=" up -d"
    
    log_info "启动命令: $START_CMD"
    log_info "正在启动服务..."
    
    # 执行启动
    if eval $START_CMD; then
        log_success "✅ 服务启动成功！"
        
        # 等待服务就绪
        log_info "等待服务就绪..."
        sleep 10
        
        # 检查服务状态
        check_services_status
        
        # 显示访问信息
        show_access_info
    else
        log_error "❌ 服务启动失败！"
        exit 1
    fi
}

# 检查服务状态
check_services_status() {
    log_info "检查服务状态..."
    
    # 检查主API服务
    if curl -s http://localhost:8000/health > /dev/null; then
        log_success "✅ API服务正常"
    else
        log_warning "⚠️  API服务未就绪，可能需要更多时间"
    fi
    
    # 检查WebUI（如果启用）
    if [[ "$ENABLE_WEBUI" == "true" ]]; then
        if curl -s http://localhost:3000 > /dev/null; then
            log_success "✅ WebUI服务正常"
        else
            log_warning "⚠️  WebUI服务未就绪"
        fi
    fi
    
    # 检查监控（如果启用）
    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        if curl -s http://localhost:9090 > /dev/null; then
            log_success "✅ 监控服务正常"
        else
            log_warning "⚠️  监控服务未就绪"
        fi
    fi
    
    # 显示容器状态
    log_info "容器状态:"
    docker-compose ps
}

# 显示访问信息
show_access_info() {
    log_header "服务访问信息"
    
    echo -e "${GREEN}🎉 MinerU M芯片全功能版已成功启动！${NC}"
    echo ""
    echo -e "${CYAN}📋 访问地址:${NC}"
    echo -e "  🔗 API服务:     ${BLUE}http://localhost:8000${NC}"
    echo -e "  📚 API文档:     ${BLUE}http://localhost:8000/docs${NC}"
    echo -e "  ❤️  健康检查:   ${BLUE}http://localhost:8000/health${NC}"
    echo -e "  📊 详细状态:   ${BLUE}http://localhost:8080/health/detailed${NC}"
    
    if [[ "$ENABLE_WEBUI" == "true" ]]; then
        echo -e "  🎨 WebUI界面:  ${BLUE}http://localhost:3000${NC}"
    fi
    
    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        echo -e "  📈 监控面板:   ${BLUE}http://localhost:3001${NC} (admin/admin123)"
        echo -e "  📊 Prometheus: ${BLUE}http://localhost:9090${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}🛠️  管理命令:${NC}"
    echo -e "  查看日志:     ${YELLOW}docker-compose logs -f mineru-full${NC}"
    echo -e "  重启服务:     ${YELLOW}docker-compose restart mineru-full${NC}"
    echo -e "  停止服务:     ${YELLOW}docker-compose down${NC}"
    echo -e "  查看状态:     ${YELLOW}docker-compose ps${NC}"
    
    echo ""
    echo -e "${CYAN}📝 快速测试:${NC}"
    echo -e "  ${YELLOW}curl http://localhost:8000/health${NC}"
    echo -e "  ${YELLOW}curl -X POST http://localhost:8000/parse -F 'file=@test.pdf'${NC}"
}

# 主函数
main() {
    # 解析命令行参数
    BUILD_ONLY=false
    START_ONLY=false
    CLEAN=false
    PULL_LATEST=false
    DEV_MODE=false
    NO_PREDOWNLOAD=false
    ENABLE_WEBUI=false
    ENABLE_MONITORING=false
    MODEL_SOURCE="huggingface"
    MODELS_CACHE=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -b|--build-only)
                BUILD_ONLY=true
                shift
                ;;
            -s|--start-only)
                START_ONLY=true
                shift
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -p|--pull-latest)
                PULL_LATEST=true
                shift
                ;;
            -d|--dev)
                DEV_MODE=true
                shift
                ;;
            -m|--models-cache)
                MODELS_CACHE="$2"
                shift 2
                ;;
            -w|--webui)
                ENABLE_WEBUI=true
                shift
                ;;
            -M|--monitoring)
                ENABLE_MONITORING=true
                shift
                ;;
            --no-predownload)
                NO_PREDOWNLOAD=true
                shift
                ;;
            --source)
                MODEL_SOURCE="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 显示欢迎信息
    log_header "MinerU M芯片全功能版构建脚本 v$VERSION"
    
    # 检查系统要求
    check_requirements
    
    # 执行清理（如果需要）
    if [[ "$CLEAN" == "true" ]]; then
        clean_resources
    fi
    
    # 拉取最新镜像（如果需要）
    if [[ "$PULL_LATEST" == "true" ]]; then
        pull_base_images
    fi
    
    # 执行操作
    if [[ "$START_ONLY" == "true" ]]; then
        # 仅启动服务
        start_services
    elif [[ "$BUILD_ONLY" == "true" ]]; then
        # 仅构建镜像
        build_image
    else
        # 完整流程：构建 + 启动
        build_image
        start_services
    fi
    
    log_success "🎉 操作完成！"
}

# 错误处理
trap 'log_error "脚本执行出错，退出码: $?"' ERR

# 运行主函数
main "$@"