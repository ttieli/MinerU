#!/bin/bash

# MinerU Docker构建状态监控脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检查构建状态
check_build_status() {
    local build_process=$(ps aux | grep "docker.*build" | grep -v grep)
    
    if [[ -n "$build_process" ]]; then
        return 0  # 构建进行中
    else
        return 1  # 构建已完成或未开始
    fi
}

# 显示构建进程信息
show_build_info() {
    local build_process=$(ps aux | grep "docker.*build" | grep -v grep)
    if [[ -n "$build_process" ]]; then
        echo "构建进程信息："
        echo "$build_process" | awk '{printf "  PID: %s, CPU: %s%%, MEM: %s%%, 运行时间: %s\n", $2, $3, $4, $10}'
    fi
}

# 显示Docker状态
show_docker_status() {
    echo
    log_info "Docker系统状态："
    
    # 显示磁盘使用
    echo "磁盘使用："
    docker system df 2>/dev/null | sed 's/^/  /'
    
    echo
    echo "镜像列表："
    docker images | grep -E "(mineru|python|REPOSITORY)" | sed 's/^/  /'
    
    echo
    echo "运行中的容器："
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sed 's/^/  /'
}

# 监控循环
monitor_build() {
    local start_time=$(date +%s)
    local check_count=0
    
    log_info "开始监控Docker构建状态..."
    echo "按 Ctrl+C 退出监控"
    echo
    
    while true; do
        clear
        echo "=========================================="
        echo "🔍 MinerU Docker构建状态监控"
        echo "=========================================="
        echo "监控时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "检查次数: $((++check_count))"
        
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local elapsed_min=$((elapsed / 60))
        local elapsed_sec=$((elapsed % 60))
        echo "运行时间: ${elapsed_min}分${elapsed_sec}秒"
        echo
        
        if check_build_status; then
            log_info "🔄 Docker构建正在进行中..."
            show_build_info
        else
            log_success "✅ Docker构建已完成或未开始"
            
            # 检查是否有新镜像
            if docker images | grep -q "mineru-m1"; then
                log_success "发现MinerU镜像："
                docker images | grep "mineru-m1" | sed 's/^/  /'
            fi
        fi
        
        show_docker_status
        
        echo
        echo "=========================================="
        echo "💡 提示："
        echo "  - 构建通常需要5-15分钟"
        echo "  - 如果构建失败，检查网络连接和依赖"
        echo "  - 可以使用 ./quick-start.sh 快速启动"
        echo "=========================================="
        
        sleep 10
    done
}

# 构建诊断
diagnose_build() {
    log_info "执行构建诊断..."
    
    echo
    echo "=== 系统信息 ==="
    system_profiler SPHardwareDataType | grep -E "(Model|Memory|Chip)" | sed 's/^/  /'
    
    echo
    echo "=== Docker版本 ==="
    docker --version | sed 's/^/  /'
    docker-compose --version | sed 's/^/  /'
    
    echo
    echo "=== Docker状态 ==="
    docker info | grep -E "(Server Version|Storage Driver|Logging Driver|Cgroup|CPUs|Total Memory)" | sed 's/^/  /'
    
    echo
    echo "=== 可用镜像 ==="
    docker images | grep -E "(python|mineru|REPOSITORY)" | sed 's/^/  /'
    
    echo
    echo "=== 构建进程 ==="
    if check_build_status; then
        ps aux | grep "docker.*build" | grep -v grep | sed 's/^/  /'
    else
        echo "  无构建进程运行"
    fi
    
    echo
    echo "=== 磁盘空间 ==="
    df -h | grep -E "(Filesystem|/System/Volumes/Data)" | sed 's/^/  /'
    
    echo
    echo "=== 文件检查 ==="
    for file in Dockerfile.minimal Dockerfile.fixed requirements-full.txt docker-compose.fixed.yml; do
        if [[ -f "$file" ]]; then
            echo "  ✅ $file 存在"
        else
            echo "  ❌ $file 缺失"
        fi
    done
}

# 快速测试构建
test_build() {
    log_info "执行快速构建测试..."
    
    # 创建测试Dockerfile
    cat > Dockerfile.test << EOF
FROM python:3.10-slim
RUN apt-get update && apt-get install -y curl
RUN pip install --no-cache-dir fastapi uvicorn
WORKDIR /app
COPY requirements-full.txt /tmp/
RUN echo "测试构建完成" > /app/test.txt
CMD ["echo", "测试镜像构建成功"]
EOF
    
    log_info "开始测试构建..."
    if docker build -f Dockerfile.test -t mineru-test:latest . 2>&1 | tee test-build.log; then
        log_success "测试构建成功！"
        docker rmi mineru-test:latest 2>/dev/null || true
    else
        log_error "测试构建失败，查看 test-build.log 了解详情"
    fi
    
    rm -f Dockerfile.test
}

# 主函数
main() {
    case "${1:-monitor}" in
        "monitor"|"-m"|"--monitor")
            monitor_build
            ;;
        "diagnose"|"-d"|"--diagnose")
            diagnose_build
            ;;
        "test"|"-t"|"--test")
            test_build
            ;;
        "help"|"-h"|"--help")
            echo "MinerU Docker构建监控脚本"
            echo
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  monitor, -m, --monitor    监控构建状态 (默认)"
            echo "  diagnose, -d, --diagnose  诊断构建环境"
            echo "  test, -t, --test          快速测试构建"
            echo "  help, -h, --help          显示帮助信息"
            echo
            echo "示例:"
            echo "  $0                        # 监控构建状态"
            echo "  $0 diagnose              # 诊断构建问题"
            echo "  $0 test                  # 测试构建环境"
            ;;
        *)
            log_error "未知选项: $1"
            echo "使用 $0 help 查看帮助信息"
            exit 1
            ;;
    esac
}

# 信号处理
trap 'echo -e "\n${YELLOW}监控已停止${NC}"; exit 0' INT TERM

# 执行主函数
main "$@" 