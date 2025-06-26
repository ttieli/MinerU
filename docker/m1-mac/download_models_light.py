#!/usr/bin/env python
"""
轻量级模型下载脚本，专为M1 Mac优化
只下载核心必需模型以减少内存占用和存储空间
"""
import os
from huggingface_hub import snapshot_download

def download_core_models():
    """下载核心模型"""
    print("正在下载核心模型...")
    
    # 只下载最必需的模型
    mineru_patterns = [
        "models/Layout/YOLO/*",  # 布局检测
        "models/MFD/YOLO/*",    # 公式检测 
        "models/OCR/paddleocr_torch/*",  # OCR识别
    ]
    
    try:
        model_dir = snapshot_download(
            "opendatalab/PDF-Extract-Kit-1.0",
            allow_patterns=mineru_patterns,
            local_dir="/opt/",
            cache_dir="/tmp/hf_cache"  # 使用临时缓存目录
        )
        print(f"核心模型下载完成: {model_dir}")
    except Exception as e:
        print(f"模型下载失败: {e}")
        print("将在运行时自动下载模型")
    
    # 下载轻量级布局阅读器
    try:
        layoutreader_pattern = [
            "*.json",
            "*.safetensors",
        ]
        layoutreader_model_dir = snapshot_download(
            "hantian/layoutreader",
            allow_patterns=layoutreader_pattern,
            local_dir="/opt/layoutreader/",
            cache_dir="/tmp/hf_cache"
        )
        print(f"布局阅读器下载完成: {layoutreader_model_dir}")
    except Exception as e:
        print(f"布局阅读器下载失败: {e}")
    
    # 清理临时缓存
    os.system("rm -rf /tmp/hf_cache")
    print("模型下载和清理完成")

if __name__ == "__main__":
    download_core_models()