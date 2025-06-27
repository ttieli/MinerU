#!/bin/bash

echo "📊 MinerU模型下载监控"
echo "===================="

while true; do
    clear
    echo "📊 $(date '+%Y-%m-%d %H:%M:%S') - 模型下载进度"
    echo "============================================"
    
    # 检查下载进程
    if pgrep -f "download_models_local.py" >/dev/null; then
        echo "🔄 下载状态: 进行中"
    else
        echo "⏹️  下载状态: 已完成或未开始"
    fi
    
    echo ""
    echo "📁 模型目录大小:"
    if [ -d "./models" ]; then
        du -sh ./models 2>/dev/null || echo "   0B"
    else
        echo "   目录不存在"
    fi
    
    if [ -d "./layoutreader" ]; then
        echo "📚 LayoutReader: $(du -sh ./layoutreader 2>/dev/null | cut -f1)"
    fi
    
    echo ""
    echo "📦 模型组件状态:"
    
    [ -d "./models/models/Layout/YOLO" ] && echo "   ✅ 布局检测" || echo "   ⏳ 布局检测"
    [ -d "./models/models/MFD/YOLO" ] && echo "   ✅ 公式检测" || echo "   ⏳ 公式检测"
    [ -d "./models/models/OCR/paddleocr_torch" ] && echo "   ✅ OCR模型" || echo "   ⏳ OCR模型"
    [ -d "./models/models/TabRec/SlanetPlus" ] && echo "   ✅ 表格识别" || echo "   ⏳ 表格识别"
    [ -d "./layoutreader" ] && [ "$(ls -A ./layoutreader 2>/dev/null)" ] && echo "   ✅ LayoutReader" || echo "   ⏳ LayoutReader"
    
    echo ""
    echo "💾 磁盘空间: $(df -h . | tail -1 | awk '{print $4 " 可用"}')"
    echo "⏱️  10秒后刷新 | Ctrl+C 退出"
    
    sleep 10
done
