#!/bin/bash

# MinerU M芯片全功能版健康检查脚本
set -e

# 配置
TIMEOUT=10
API_HOST="localhost"
API_PORT="8000"
HEALTH_ENDPOINT="/health"

# 检查API服务是否响应
check_api_health() {
    local url="http://${API_HOST}:${API_PORT}${HEALTH_ENDPOINT}"
    
    if curl -s --max-time $TIMEOUT "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检查详细健康状态
check_detailed_health() {
    local url="http://${API_HOST}:8080/health/detailed"
    
    if curl -s --max-time $TIMEOUT "$url" | grep -q '"status":"healthy"' 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 检查进程是否运行
check_process() {
    if pgrep -f "python.*app.py" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 主健康检查
main() {
    local exit_code=0
    
    # 检查主进程
    if ! check_process; then
        echo "FAIL: MinerU进程未运行"
        exit_code=1
    fi
    
    # 检查API健康
    if ! check_api_health; then
        echo "FAIL: API健康检查失败"
        exit_code=1
    fi
    
    # 检查详细状态（可选）
    if ! check_detailed_health; then
        echo "WARN: 详细健康检查失败，但基础API正常"
        # 不设为失败，因为基础API可用
    fi
    
    if [ $exit_code -eq 0 ]; then
        echo "OK: MinerU服务健康"
    fi
    
    exit $exit_code
}

# 运行健康检查
main "$@"