#!/bin/bash
set -e

# MinerU M芯片全功能版启动脚本
echo "🚀 启动 MinerU M芯片全功能版..."

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

# 检查系统信息
check_system() {
    log_info "检查系统信息..."
    
    # 检查Python版本
    python_version=$(python --version 2>&1)
    log_info "Python版本: $python_version"
    
    # 检查平台信息
    platform=$(python -c "import platform; print(platform.platform())")
    log_info "平台: $platform"
    
    # 检查MPS支持
    if python -c "import torch; print(torch.backends.mps.is_available())" 2>/dev/null | grep -q "True"; then
        log_success "✅ MPS支持已启用"
        export DEVICE_MODE=mps
    else
        log_warning "⚠️  MPS不可用，将使用CPU模式"
        export DEVICE_MODE=cpu
    fi
    
    # 检查内存
    memory_info=$(python -c "import psutil; mem=psutil.virtual_memory(); print(f'{mem.total//1024//1024//1024}GB total, {mem.available//1024//1024//1024}GB available')" 2>/dev/null || echo "Unknown")
    log_info "内存信息: $memory_info"
}

# 环境变量设置
setup_environment() {
    log_info "设置环境变量..."
    
    # 基础环境
    export PYTHONPATH="/app:$PYTHONPATH"
    export PYTHONUNBUFFERED=1
    export PYTHONDONTWRITEBYTECODE=1
    
    # MinerU配置
    export MINERU_MODEL_SOURCE=${MINERU_MODEL_SOURCE:-huggingface}
    export MINERU_CONFIG_PATH="/root/magic-pdf.json"
    
    # 设备配置
    export DEVICE_MODE=${DEVICE_MODE:-mps}
    
    # PyTorch MPS优化
    if [ "$DEVICE_MODE" = "mps" ]; then
        export PYTORCH_ENABLE_MPS_FALLBACK=1
        export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
        export MPS_MEMORY_FRACTION=${MPS_MEMORY_FRACTION:-0.8}
    fi
    
    # 性能配置
    export MAX_WORKERS=${MAX_WORKERS:-4}
    export BATCH_SIZE=${BATCH_SIZE:-2}
    export WORKER_PROCESSES=${WORKER_PROCESSES:-4}
    export WORKER_THREADS=${WORKER_THREADS:-2}
    
    # 内存优化
    export MEMORY_EFFICIENT_MODE=${MEMORY_EFFICIENT_MODE:-true}
    export MODEL_OFFLOAD_CPU=${MODEL_OFFLOAD_CPU:-true}
    export CLEAR_CACHE_INTERVAL=${CLEAR_CACHE_INTERVAL:-100}
    
    # 功能开关
    export ENABLE_VLM=${ENABLE_VLM:-true}
    export ENABLE_PIPELINE=${ENABLE_PIPELINE:-true}
    export ENABLE_TABLE=${ENABLE_TABLE:-true}
    export ENABLE_FORMULA=${ENABLE_FORMULA:-true}
    export ENABLE_LLM_AIDED=${ENABLE_LLM_AIDED:-false}
    
    # 日志配置
    export LOG_LEVEL=${LOG_LEVEL:-INFO}
    export LOG_FORMAT=${LOG_FORMAT:-json}
    
    log_success "环境变量设置完成"
}

# 检查和创建目录
setup_directories() {
    log_info "设置目录结构..."
    
    # 创建必要目录
    directories=(
        "/app/output"
        "/app/temp"
        "/app/logs"
        "/app/cache"
        "/opt/models"
        "/opt/layoutreader"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "创建目录: $dir"
        fi
    done
    
    # 设置权限
    chown -R mineru:mineru /app/output /app/temp /app/logs /app/cache 2>/dev/null || true
    
    log_success "目录设置完成"
}

# 检查和下载模型
check_models() {
    log_info "检查模型文件..."
    
    # 检查是否需要下载模型
    model_info_file="/opt/models/model_info.json"
    
    if [ ! -f "$model_info_file" ]; then
        log_warning "模型文件不存在，开始下载..."
        
        # 根据启用的功能决定下载模式
        download_mode="essential"
        if [ "$ENABLE_VLM" = "true" ] && [ "$ENABLE_PIPELINE" = "true" ]; then
            download_mode="all"
        elif [ "$ENABLE_VLM" = "true" ]; then
            download_mode="vlm"
        elif [ "$ENABLE_PIPELINE" = "true" ]; then
            download_mode="pipeline"
        fi
        
        log_info "下载模式: $download_mode"
        
        # 执行模型下载
        if python download_models_full.py --mode "$download_mode" --source "$MINERU_MODEL_SOURCE" --cleanup; then
            log_success "✅ 模型下载完成"
        else
            log_error "❌ 模型下载失败"
            exit 1
        fi
    else
        log_success "✅ 模型文件已存在"
        
        # 验证模型完整性
        if python download_models_full.py --verify; then
            log_success "✅ 模型验证通过"
        else
            log_warning "⚠️  模型验证失败，可能需要重新下载"
        fi
    fi
}

# 等待依赖服务
wait_for_services() {
    log_info "等待依赖服务..."
    
    # 等待Redis（如果启用缓存）
    if [ "${CACHE_ENABLE:-true}" = "true" ]; then
        redis_host=$(echo "${REDIS_URL:-redis://redis:6379/0}" | sed 's|redis://||' | sed 's|/.*||' | sed 's|:.*||')
        redis_port=$(echo "${REDIS_URL:-redis://redis:6379/0}" | sed 's|.*:||' | sed 's|/.*||')
        
        log_info "等waiting for Redis at $redis_host:$redis_port..."
        
        timeout=30
        count=0
        while ! nc -z "$redis_host" "$redis_port" 2>/dev/null; do
            if [ $count -ge $timeout ]; then
                log_warning "⚠️  Redis服务不可用，将禁用缓存功能"
                export CACHE_ENABLE=false
                break
            fi
            sleep 1
            count=$((count + 1))
        done
        
        if [ "$CACHE_ENABLE" = "true" ]; then
            log_success "✅ Redis服务可用"
        fi
    fi
}

# 预热模型
warmup_models() {
    log_info "预热模型..."
    
    # 检查是否需要预热
    if [ "${ENABLE_MODEL_WARMUP:-true}" = "true" ]; then
        log_info "正在预热模型，这可能需要几分钟..."
        
        # 创建预热脚本
        cat > /tmp/warmup.py << 'EOF'
import os
import sys
import warnings
warnings.filterwarnings("ignore")

try:
    # 预热Pipeline模型
    if os.getenv('ENABLE_PIPELINE', 'true') == 'true':
        print("预热Pipeline模型...")
        from mineru.backend.pipeline.pipeline_analyze import custom_model_init
        custom_model_init()
        print("✅ Pipeline模型预热完成")
    
    # 预热VLM模型
    if os.getenv('ENABLE_VLM', 'true') == 'true':
        print("预热VLM模型...")
        try:
            from mineru.backend.vlm.vlm_analyze import doc_analyze
            print("✅ VLM模型预热完成")
        except Exception as e:
            print(f"⚠️  VLM模型预热失败: {e}")
    
    print("🎉 模型预热完成！")
    
except Exception as e:
    print(f"⚠️  模型预热过程中出现错误: {e}")
    print("将在运行时动态加载模型")
EOF
        
        # 执行预热
        python /tmp/warmup.py || log_warning "⚠️  模型预热失败，将在运行时加载"
        rm -f /tmp/warmup.py
    else
        log_info "跳过模型预热"
    fi
}

# 启动健康检查服务
start_health_check() {
    log_info "启动健康检查服务..."
    
    # 创建健康检查端点
    cat > /tmp/health_server.py << 'EOF'
import asyncio
import json
from aiohttp import web
import psutil
import os

async def health_check(request):
    """基础健康检查"""
    return web.json_response({
        "status": "healthy",
        "service": "mineru-full",
        "version": "2.0-full"
    })

async def detailed_health(request):
    """详细健康检查"""
    try:
        # 系统信息
        memory = psutil.virtual_memory()
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # 模型状态
        models_status = {}
        if os.path.exists("/opt/models/model_info.json"):
            with open("/opt/models/model_info.json", "r") as f:
                model_info = json.load(f)
                models_status = model_info.get("verification", {})
        
        return web.json_response({
            "status": "healthy",
            "service": "mineru-full",
            "system": {
                "memory_percent": memory.percent,
                "memory_available": memory.available // 1024 // 1024,
                "cpu_percent": cpu_percent
            },
            "models": models_status,
            "config": {
                "device_mode": os.getenv("DEVICE_MODE", "cpu"),
                "enable_vlm": os.getenv("ENABLE_VLM", "false"),
                "enable_pipeline": os.getenv("ENABLE_PIPELINE", "false")
            }
        })
    except Exception as e:
        return web.json_response({
            "status": "error",
            "error": str(e)
        }, status=500)

# 启动健康检查服务器
app = web.Application()
app.router.add_get('/health', health_check)
app.router.add_get('/health/detailed', detailed_health)

if __name__ == '__main__':
    web.run_app(app, host='0.0.0.0', port=8080)
EOF
    
    # 后台启动健康检查服务
    python /tmp/health_server.py &
    health_pid=$!
    log_success "✅ 健康检查服务已启动 (PID: $health_pid)"
}

# 主函数
main() {
    log_info "🎯 MinerU M芯片全功能版启动中..."
    
    # 执行初始化步骤
    check_system
    setup_environment
    setup_directories
    wait_for_services
    check_models
    warmup_models
    start_health_check
    
    # 显示配置摘要
    log_info "📋 配置摘要:"
    log_info "  设备模式: $DEVICE_MODE"
    log_info "  VLM模式: $ENABLE_VLM"
    log_info "  Pipeline模式: $ENABLE_PIPELINE"
    log_info "  表格识别: $ENABLE_TABLE"
    log_info "  公式识别: $ENABLE_FORMULA"
    log_info "  最大工作进程: $MAX_WORKERS"
    log_info "  批处理大小: $BATCH_SIZE"
    
    log_success "🎉 初始化完成！"
    log_info "🚀 启动MinerU API服务..."
    
    # 启动主应用
    if [ "$#" -eq 0 ]; then
        # 默认启动参数
        exec python app.py
    else
        # 使用传入的参数
        exec python app.py "$@"
    fi
}

# 信号处理
cleanup() {
    log_info "🛑 正在关闭服务..."
    
    # 清理临时文件
    rm -f /tmp/warmup.py /tmp/health_server.py
    
    # 杀死健康检查进程
    if [ ! -z "$health_pid" ]; then
        kill $health_pid 2>/dev/null || true
    fi
    
    log_success "✅ 清理完成"
    exit 0
}

# 注册信号处理
trap cleanup SIGTERM SIGINT

# 运行主函数
main "$@"