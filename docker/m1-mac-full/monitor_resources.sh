#!/bin/bash

# MinerU资源监控脚本
# 实时监控内存、CPU使用情况

echo "🔍 MinerU全功能版资源监控"
echo "按 Ctrl+C 退出监控"
echo ""

while true; do
    clear
    echo "📊 $(date '+%Y-%m-%d %H:%M:%S') - MinerU资源监控"
    echo "======================================================"
    
    # 系统总体内存使用
    echo "💾 系统内存使用："
    vm_stat | head -6 | while read line; do
        echo "   $line"
    done
    
    echo ""
    
    # Docker容器资源使用
    echo "🐳 Docker容器资源使用："
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" \
        $(docker ps --filter "name=mineru" --format "{{.Names}}") 2>/dev/null || echo "   MinerU容器未运行"
    
    echo ""
    
    # MinerU特定监控
    if docker ps --filter "name=mineru-full-api" --format "{{.Names}}" | grep -q mineru-full-api; then
        echo "🎯 MinerU详细状态："
        
        # 容器状态
        STATUS=$(docker inspect mineru-full-api --format '{{.State.Status}}')
        HEALTH=$(docker inspect mineru-full-api --format '{{.State.Health.Status}}' 2>/dev/null || echo "no-health")
        echo "   状态: $STATUS"
        echo "   健康: $HEALTH"
        
        # API健康检查
        if curl -s http://localhost:8008/health >/dev/null 2>&1; then
            echo "   API: ✅ 正常响应"
        else
            echo "   API: ❌ 无响应"
        fi
        
        # 内存使用详情
        MEM_USAGE=$(docker stats --no-stream --format "{{.MemUsage}}" mineru-full-api 2>/dev/null)
        echo "   内存: $MEM_USAGE"
        
        # 进程数
        PROCESSES=$(docker exec mineru-full-api ps aux | wc -l 2>/dev/null || echo "N/A")
        echo "   进程数: $PROCESSES"
        
    else
        echo "🎯 MinerU状态: ❌ 未运行"
    fi
    
    echo ""
    echo "📈 端口监听状态："
    netstat -an | grep LISTEN | grep -E ':(8008|8088|6379)' | while read line; do
        echo "   $line"
    done
    
    echo ""
    echo "⏱️  更新间隔: 5秒 | 按 Ctrl+C 退出"
    
    sleep 5
done
