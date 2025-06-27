#!/bin/bash

# MinerU M芯片全功能版快速启动脚本
# 适用于快速测试和验证

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker Desktop"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装"
        exit 1
    fi
    
    # 检查系统内存
    MEMORY_GB=$(system_profiler SPHardwareDataType | grep "Memory:" | awk '{print $2}' | cut -d' ' -f1)
    if [[ $MEMORY_GB -lt 16 ]]; then
        log_warning "系统内存少于16GB，可能影响性能"
    fi
    
    log_success "系统要求检查完成"
}

# 检查模型文件
check_models() {
    log_info "检查模型文件..."
    
    if [[ ! -d "models" ]] || [[ ! -d "layoutreader" ]]; then
        log_warning "模型文件缺失，请先下载模型"
        log_info "运行: python download_models_full.py --mode=full"
        return 1
    fi
    
    MODEL_SIZE=$(du -sh models/ 2>/dev/null | cut -f1 || echo "0")
    LAYOUT_SIZE=$(du -sh layoutreader/ 2>/dev/null | cut -f1 || echo "0")
    
    log_success "模型文件检查完成 (models: $MODEL_SIZE, layoutreader: $LAYOUT_SIZE)"
}

# 创建环境配置
create_env() {
    log_info "创建环境配置..."
    
    cat > .env << EOF
# MinerU M芯片全功能版配置
# 自动生成于 $(date)

# ========== 服务端口配置 ==========
API_PORT=8100
REDIS_PORT=6380

# ========== 资源配置 ==========
MEMORY_LIMIT=16G
MPS_MEMORY_FRACTION=0.8
MAX_WORKERS=6
BATCH_SIZE=2

# ========== 设备配置 ==========
DEVICE_TYPE=mps
ENABLE_MPS=true

# ========== 功能开关 ==========
ENABLE_LAYOUT_DETECTION=true
ENABLE_FORMULA_DETECTION=true
ENABLE_TABLE_DETECTION=true
ENABLE_OCR=true

# ========== 性能优化 ==========
SMART_MEMORY_MANAGEMENT=true
AUTO_BATCH_SIZE=true
CONCURRENT_PROCESSING=true

# ========== 日志配置 ==========
LOG_LEVEL=INFO
LOG_FILE=/app/logs/mineru.log

# ========== 缓存配置 ==========
REDIS_MAX_MEMORY=2G
REDIS_EVICTION_POLICY=allkeys-lru
EOF
    
    log_success "环境配置文件已创建"
}

# 构建镜像
build_image() {
    log_info "构建Docker镜像..."
    
    # 检查是否有现成的镜像可用
    if docker images | grep -q "mineru-m1-minimal"; then
        log_info "发现现有镜像，跳过构建"
        return 0
    fi
    
    # 使用最小化Dockerfile构建
    if [[ -f "Dockerfile.minimal" ]]; then
        log_info "使用最小化Dockerfile构建..."
        docker build -f Dockerfile.minimal -t mineru-m1-minimal:latest . || {
            log_error "镜像构建失败"
            return 1
        }
    else
        log_warning "Dockerfile.minimal不存在，使用修复版Dockerfile"
        docker build -f Dockerfile.fixed -t mineru-m1-full:latest . || {
            log_error "镜像构建失败"
            return 1
        }
    fi
    
    log_success "Docker镜像构建完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    # 停止现有服务
    docker-compose -f docker-compose.fixed.yml down 2>/dev/null || true
    
    # 启动服务
    docker-compose -f docker-compose.fixed.yml up -d || {
        log_error "服务启动失败"
        return 1
    }
    
    log_success "服务启动完成"
}

# 验证服务
verify_services() {
    log_info "验证服务状态..."
    
    # 等待服务启动
    sleep 10
    
    # 检查容器状态
    if ! docker-compose -f docker-compose.fixed.yml ps | grep -q "Up"; then
        log_error "容器未正常启动"
        docker-compose -f docker-compose.fixed.yml logs
        return 1
    fi
    
    # 检查健康状态
    for i in {1..30}; do
        if curl -s http://localhost:8100/health >/dev/null 2>&1; then
            log_success "服务健康检查通过"
            break
        fi
        
        if [[ $i -eq 30 ]]; then
            log_error "服务健康检查失败"
            return 1
        fi
        
        log_info "等待服务启动... ($i/30)"
        sleep 2
    done
}

# 显示服务信息
show_info() {
    log_success "MinerU全功能版启动成功！"
    echo
    echo "🌐 服务访问地址："
    echo "  - API服务: http://localhost:8100"
    echo "  - API文档: http://localhost:8100/docs"
    echo "  - 健康检查: http://localhost:8100/health"
    echo
    echo "📊 服务状态："
    docker-compose -f docker-compose.fixed.yml ps
    echo
    echo "🔧 常用命令："
    echo "  - 查看日志: docker-compose -f docker-compose.fixed.yml logs -f"
    echo "  - 重启服务: docker-compose -f docker-compose.fixed.yml restart"
    echo "  - 停止服务: docker-compose -f docker-compose.fixed.yml down"
    echo
    echo "🧪 测试命令："
    echo "  curl -X POST http://localhost:8100/parse -F \"file=@your_file.pdf\""
}

# 主函数
main() {
    echo "=========================================="
    echo "🚀 MinerU M芯片全功能版快速启动"
    echo "=========================================="
    echo
    
    # 检查参数
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        echo "用法: $0 [选项]"
        echo
        echo "选项:"
        echo "  -h, --help     显示帮助信息"
        echo "  -c, --clean    清理并重新开始"
        echo "  -b, --build    仅构建镜像"
        echo "  -s, --start    仅启动服务"
        echo
        exit 0
    fi
    
    # 清理选项
    if [[ "$1" == "-c" ]] || [[ "$1" == "--clean" ]]; then
        log_info "清理现有资源..."
        docker-compose -f docker-compose.fixed.yml down 2>/dev/null || true
        docker rmi mineru-m1-minimal:latest 2>/dev/null || true
        docker rmi mineru-m1-full:latest 2>/dev/null || true
        log_success "清理完成"
    fi
    
    # 执行步骤
    check_requirements
    
    if [[ "$1" != "-s" ]] && [[ "$1" != "--start" ]]; then
        check_models || log_warning "模型文件检查失败，但继续执行"
        create_env
        build_image || {
            log_error "构建失败，请检查错误信息"
            exit 1
        }
    fi
    
    if [[ "$1" != "-b" ]] && [[ "$1" != "--build" ]]; then
        start_services || {
            log_error "启动失败，请检查错误信息"
            exit 1
        }
        
        verify_services || {
            log_error "验证失败，请检查服务状态"
            exit 1
        }
        
        show_info
    fi
    
    log_success "快速启动完成！"
}

# 执行主函数
main "$@"