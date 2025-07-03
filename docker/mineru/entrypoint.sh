#!/bin/bash
# MinerU 统一启动脚本

set -e

# 显示启动信息
echo "🚀 启动 MinerU ${MINERU_VERSION:-simple} 版本"
echo "📅 启动时间: $(date)"
echo "🔧 Python版本: $(python --version)"
echo "💾 内存信息: $(free -h | grep Mem)"
echo "🖥️  CPU信息: $(nproc) 核心"

# 检查必要的目录
echo "📁 检查目录结构..."
mkdir -p /app/output /app/temp /app/cache /app/logs

# 检查模型文件
echo "🧠 检查模型文件..."
if [ "$MINERU_VERSION" = "full" ]; then
    echo "   - 完整版模型检查..."
    if [ ! -d "/opt/models" ] || [ -z "$(ls -A /opt/models)" ]; then
        echo "⚠️  模型目录为空，将在运行时下载"
    else
        echo "✅ 模型文件已存在"
    fi
else
    echo "   - 简化版模型检查..."
    if [ ! -d "/opt/models" ] || [ -z "$(ls -A /opt/models)" ]; then
        echo "⚠️  模型目录为空，将在运行时下载"
    else
        echo "✅ 模型文件已存在"
    fi
fi

# 设置环境变量
export PYTHONPATH="/app:$PYTHONPATH"

# 显示配置信息
echo "🔧 当前配置:"
echo "   - 版本: ${MINERU_VERSION:-simple}"
echo "   - 端口: 8000"
echo "   - 线程池: ${THREAD_POOL_SIZE:-auto}"
echo "   - 设备: ${DEVICE_MODE:-cpu}"

# 检查网络连接
echo "🌐 检查网络连接..."
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ 网络连接正常"
else
    echo "⚠️  网络连接可能有问题"
fi

echo "🎯 准备启动服务..."
echo "========================================"

# 执行传入的命令
exec "$@"