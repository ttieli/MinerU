#!/bin/bash

# MinerU M芯片全功能版完整构建脚本 (修复版)
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 版本信息
VERSION="2.0-full-fixed"
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
    echo "MinerU M芯片全功能版完整构建脚本 (修复版)"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示此帮助信息"
    echo "  -b, --build-only        仅构建镜像，不启动服务"
    echo "  -s, --start-only        仅启动服务（需要已构建的镜像）"
    echo "  -c, --clean             清理现有镜像和容器"
    echo "  -p, --pull-latest       拉取最新基础镜像"
    echo "  -d, --download-models   重新下载模型"
    echo "  --source SOURCE         模型源 (huggingface|modelscope)"
    echo ""
    echo "示例:"
    echo "  $0                      # 完整构建并启动"
    echo "  $0 -b                   # 仅构建镜像"
    echo "  $0 -s                   # 仅启动服务"
    echo "  $0 -d                   # 重新下载模型"
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
    
    log_success "系统要求检查完成"
}

# 清理现有资源
clean_resources() {
    log_header "清理现有资源"
    
    log_info "停止现有容器..."
    docker-compose -f docker-compose.fixed.yml down --remove-orphans 2>/dev/null || true
    
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
    
    log_info "拉取Redis镜像..."
    docker pull redis:7-alpine
    
    log_success "基础镜像拉取完成"
}

# 下载模型
download_models() {
    log_header "下载MinerU全功能版模型"
    
    if [[ ! -f "download_models_full.py" ]]; then
        log_error "下载脚本不存在: download_models_full.py"
        exit 1
    fi
    
    log_info "设置模型源: $MODEL_SOURCE"
    export MINERU_MODEL_SOURCE=$MODEL_SOURCE
    
    log_info "开始下载模型..."
    if python download_models_full.py --mode=full; then
        log_success "模型下载完成"
        
        # 显示模型信息
        log_info "已下载的模型:"
        if [[ -d "./models" ]]; then
            du -sh ./models/* 2>/dev/null || echo "  模型目录为空"
        fi
        if [[ -d "./layoutreader" ]]; then
            du -sh ./layoutreader/* 2>/dev/null || echo "  LayoutReader目录为空"
        fi
    else
        log_error "模型下载失败"
        exit 1
    fi
}

# 构建镜像
build_image() {
    log_header "构建MinerU全功能镜像"
    
    # 检查模型是否存在
    if [[ ! -d "./models" ]] || [[ -z "$(ls -A ./models 2>/dev/null)" ]]; then
        log_warning "本地模型不存在，将在构建过程中下载"
    else
        log_success "检测到本地模型，将使用现有模型"
    fi
    
    # 设置构建参数
    BUILD_ARGS=(
        --build-arg BUILD_DATE="$BUILD_DATE"
        --build-arg VERSION="$VERSION"
        --platform linux/arm64
        --no-cache
    )
    
    log_info "开始构建镜像..."
    log_info "构建参数: ${BUILD_ARGS[*]}"
    
    # 执行构建
    if docker build "${BUILD_ARGS[@]}" -f Dockerfile.fixed -t mineru-m1-full:$VERSION -t mineru-m1-full:latest .; then
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
# MinerU M芯片全功能版配置 (修复版)
VERSION=$VERSION
BUILD_DATE=$BUILD_DATE

# 模型源配置
MINERU_MODEL_SOURCE=${MODEL_SOURCE:-huggingface}

# 端口配置
API_PORT=8000
MONITOR_PORT=8080

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

# 日志配置
LOG_LEVEL=INFO
LOG_FORMAT=json
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
        "./logs"
        "./cache"
        "./models"
        "./layoutreader"
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
    
    log_info "正在启动服务..."
    
    # 执行启动
    if docker-compose -f docker-compose.fixed.yml up -d; then
        log_success "✅ 服务启动成功！"
        
        # 等待服务就绪
        log_info "等待服务就绪..."
        sleep 15
        
        # 检查服务状态
        check_services_status
        
        # 显示访问信息
        show_access_info
    else
        log_error "❌ 服务启动失败！"
        
        log_info "查看启动日志:"
        docker-compose -f docker-compose.fixed.yml logs --tail 20
        
        exit 1
    fi
}

# 检查服务状态
check_services_status() {
    log_info "检查服务状态..."
    
    # 显示容器状态
    log_info "容器状态:"
    docker-compose -f docker-compose.fixed.yml ps
    
    # 检查主API服务
    log_info "等待API服务启动..."
    for i in {1..12}; do
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            log_success "✅ API服务正常"
            break
        else
            if [[ $i -eq 12 ]]; then
                log_warning "⚠️  API服务启动超时，请检查日志"
                log_info "查看服务日志:"
                docker-compose -f docker-compose.fixed.yml logs mineru-full --tail 10
            else
                log_info "等待API服务启动... ($i/12)"
                sleep 5
            fi
        fi
    done
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
    echo -e "  📊 状态监控:   ${BLUE}http://localhost:8080${NC}"
    
    echo ""
    echo -e "${CYAN}🛠️  管理命令:${NC}"
    echo -e "  查看日志:     ${YELLOW}docker-compose -f docker-compose.fixed.yml logs -f mineru-full${NC}"
    echo -e "  重启服务:     ${YELLOW}docker-compose -f docker-compose.fixed.yml restart mineru-full${NC}"
    echo -e "  停止服务:     ${YELLOW}docker-compose -f docker-compose.fixed.yml down${NC}"
    echo -e "  查看状态:     ${YELLOW}docker-compose -f docker-compose.fixed.yml ps${NC}"
    
    echo ""
    echo -e "${CYAN}📝 快速测试:${NC}"
    echo -e "  ${YELLOW}curl http://localhost:8000/health${NC}"
    echo -e "  ${YELLOW}curl -X POST http://localhost:8000/parse -F 'file=@test.pdf'${NC}"
    
    echo ""
    echo -e "${CYAN}📁 本地目录映射:${NC}"
    echo -e "  模型目录:     ${YELLOW}./models -> /opt/models${NC}"
    echo -e "  输出目录:     ${YELLOW}./output -> /app/output${NC}"
    echo -e "  日志目录:     ${YELLOW}./logs -> /app/logs${NC}"
    echo -e "  缓存目录:     ${YELLOW}./cache -> /app/cache${NC}"
}

# 主函数
main() {
    # 解析命令行参数
    BUILD_ONLY=false
    START_ONLY=false
    CLEAN=false
    PULL_LATEST=false
    DOWNLOAD_MODELS=false
    MODEL_SOURCE="huggingface"
    
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
            -d|--download-models)
                DOWNLOAD_MODELS=true
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
    log_header "MinerU M芯片全功能版完整构建脚本 v$VERSION"
    
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
    
    # 下载模型（如果需要）
    if [[ "$DOWNLOAD_MODELS" == "true" ]]; then
        download_models
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