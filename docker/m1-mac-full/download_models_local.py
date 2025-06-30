#!/usr/bin/env python3
"""
MinerU 本地模型下载器
使用当前目录作为模型存储位置
"""

import os
import sys
from pathlib import Path
from typing import List, Optional, Dict
import logging

# 设置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s | %(levelname)s | %(message)s')
logger = logging.getLogger(__name__)

try:
    from huggingface_hub import snapshot_download
except ImportError:
    logger.error("请安装 huggingface_hub: pip install huggingface_hub")
    sys.exit(1)

class LocalModelDownloader:
    """本地模型下载器"""
    
    def __init__(self, base_dir: str = "."):
        self.base_dir = Path(base_dir)
        self.models_dir = self.base_dir / "models"
        self.layoutreader_dir = self.base_dir / "layoutreader"
        
        # 创建目录
        self.models_dir.mkdir(parents=True, exist_ok=True)
        self.layoutreader_dir.mkdir(parents=True, exist_ok=True)
        
        logger.info(f"模型目录: {self.models_dir.absolute()}")
        logger.info(f"LayoutReader目录: {self.layoutreader_dir.absolute()}")
    
    def download_essential_models(self) -> bool:
        """下载核心必需模型"""
        logger.info("🚀 开始下载MinerU核心模型...")
        
        models_to_download = [
            {
                "name": "PDF-Extract-Kit (核心组件)",
                "repo_id": "opendatalab/PDF-Extract-Kit-1.0",
                "patterns": [
                    "models/Layout/YOLO/*",           # 布局检测
                    "models/MFD/YOLO/*",              # 公式检测
                    "models/OCR/paddleocr_torch/*",   # OCR
                    "models/TabRec/SlanetPlus/*",     # 表格识别
                ],
                "local_dir": self.models_dir
            },
            {
                "name": "LayoutReader (阅读顺序)",
                "repo_id": "hantian/layoutreader",
                "patterns": ["*.json", "*.safetensors", "*.bin"],
                "local_dir": self.layoutreader_dir
            }
        ]
        
        success = True
        for model in models_to_download:
            logger.info(f"📦 下载 {model['name']}...")
            try:
                local_dir = snapshot_download(
                    repo_id=model["repo_id"],
                    allow_patterns=model["patterns"],
                    local_dir=str(model["local_dir"]),
                    cache_dir="/tmp/hf_cache",
                    resume_download=True,
                    local_files_only=False
                )
                logger.info(f"✅ {model['name']} 下载完成")
            except Exception as e:
                logger.error(f"❌ {model['name']} 下载失败: {e}")
                success = False
        
        return success
    
    def download_full_models(self) -> bool:
        """下载完整模型集"""
        logger.info("🚀 开始下载MinerU完整模型...")
        
        # 先下载核心模型
        if not self.download_essential_models():
            return False
        
        # 下载额外模型
        additional_models = [
            {
                "name": "公式识别模型",
                "repo_id": "opendatalab/PDF-Extract-Kit-1.0",
                "patterns": ["models/MFR/unimernet_hf_small_2503/*"],
                "local_dir": self.models_dir
            },
            {
                "name": "VLM多模态模型",
                "repo_id": "opendatalab/MinerU2.0-2505-0.9B",
                "patterns": None,  # 下载全部
                "local_dir": self.models_dir / "vlm"
            }
        ]
        
        success = True
        for model in additional_models:
            logger.info(f"📦 下载 {model['name']}...")
            try:
                kwargs = {
                    "repo_id": model["repo_id"],
                    "local_dir": str(model["local_dir"]),
                    "cache_dir": "/tmp/hf_cache",
                    "resume_download": True,
                    "local_files_only": False
                }
                
                if model["patterns"]:
                    kwargs["allow_patterns"] = model["patterns"]
                
                local_dir = snapshot_download(**kwargs)
                logger.info(f"✅ {model['name']} 下载完成")
            except Exception as e:
                logger.error(f"❌ {model['name']} 下载失败: {e}")
                success = False
        
        return success
    
    def verify_models(self) -> Dict[str, bool]:
        """验证模型完整性"""
        logger.info("🔍 验证模型完整性...")
        
        checks = {
            "布局检测模型": (self.models_dir / "models/Layout/YOLO").exists(),
            "公式检测模型": (self.models_dir / "models/MFD/YOLO").exists(),
            "OCR模型": (self.models_dir / "models/OCR/paddleocr_torch").exists(),
            "表格识别模型": (self.models_dir / "models/TabRec/SlanetPlus").exists(),
            "LayoutReader": any(self.layoutreader_dir.glob("*.safetensors")),
        }
        
        for name, status in checks.items():
            status_icon = "✅" if status else "❌"
            logger.info(f"  {status_icon} {name}")
        
        return checks

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="MinerU 本地模型下载器")
    parser.add_argument("--mode", choices=["essential", "full"], default="essential",
                       help="下载模式")
    parser.add_argument("--verify", action="store_true", help="只验证模型")
    
    args = parser.parse_args()
    
    downloader = LocalModelDownloader()
    
    if args.verify:
        checks = downloader.verify_models()
        all_good = all(checks.values())
        logger.info(f"验证结果: {'✅ 全部就绪' if all_good else '❌ 缺少模型'}")
        return 0 if all_good else 1
    
    if args.mode == "essential":
        success = downloader.download_essential_models()
    else:
        success = downloader.download_full_models()
    
    if success:
        logger.info("🎉 模型下载完成！")
        downloader.verify_models()
        return 0
    else:
        logger.error("❌ 模型下载失败")
        return 1

if __name__ == "__main__":
    sys.exit(main())
