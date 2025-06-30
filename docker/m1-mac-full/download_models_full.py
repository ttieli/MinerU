#!/usr/bin/env python3
"""
MinerU 全功能版模型下载脚本
支持Pipeline和VLM模式的完整模型下载
针对Apple Silicon优化
"""
import os
import sys
import json
import argparse
from pathlib import Path
from typing import List, Dict, Optional
from huggingface_hub import snapshot_download
from loguru import logger

# 配置日志
logger.remove()
logger.add(sys.stdout, level="INFO", format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | {message}")

class ModelDownloader:
    """模型下载管理器"""
    
    def __init__(self, model_source: str = "huggingface"):
        self.model_source = model_source
        self.models_dir = Path("/opt/models")
        self.layoutreader_dir = Path("/opt/layoutreader")
        
        # 确保目录存在
        self.models_dir.mkdir(parents=True, exist_ok=True)
        self.layoutreader_dir.mkdir(parents=True, exist_ok=True)
        
        # 模型配置
        self.model_configs = self._load_model_configs()
    
    def _load_model_configs(self) -> Dict:
        """加载模型配置"""
        return {
            "pipeline_models": {
                "repo_id": "opendatalab/PDF-Extract-Kit-1.0",
                "components": {
                    # 布局检测模型
                    "layout": {
                        "patterns": ["models/Layout/YOLO/*"],
                        "description": "DocLayout YOLO - 文档布局检测"
                    },
                    # 公式检测模型
                    "formula_detection": {
                        "patterns": ["models/MFD/YOLO/*"],
                        "description": "YOLO v8 MFD - 数学公式检测"
                    },
                    # 公式识别模型
                    "formula_recognition": {
                        "patterns": ["models/MFR/unimernet_hf_small_2503/*"],
                        "description": "UniMerNet - 数学公式识别"
                    },
                    # OCR模型
                    "ocr": {
                        "patterns": ["models/OCR/paddleocr_torch/*"],
                        "description": "PaddleOCR PyTorch - 文字识别"
                    },
                    # 表格识别模型
                    "table": {
                        "patterns": ["models/TabRec/SlanetPlus/*"],
                        "description": "SlaNet Plus - 表格识别"
                    },
                    # 阅读顺序模型
                    "reading_order": {
                        "patterns": ["models/ReadingOrder/layout_reader/*"],
                        "description": "LayoutReader - 阅读顺序检测"
                    }
                }
            },
            "vlm_models": {
                "repo_id": "opendatalab/MinerU2.0-2505-0.9B",
                "description": "MinerU 2.0 多模态大模型",
                "components": {
                    "main_model": {
                        "patterns": ["*.json", "*.safetensors", "*.bin", "tokenizer*"],
                        "description": "主模型文件和分词器"
                    },
                    "vision_tower": {
                        "patterns": ["vision_tower/*"],
                        "description": "视觉编码器"
                    },
                    "mm_projector": {
                        "patterns": ["mm_projector/*"],
                        "description": "多模态投影器"
                    }
                }
            },
            "layoutreader": {
                "repo_id": "hantian/layoutreader",
                "description": "LayoutReader - 阅读顺序检测",
                "components": {
                    "model": {
                        "patterns": ["*.json", "*.safetensors", "*.bin"],
                        "description": "LayoutReader模型文件"
                    }
                }
            }
        }
    
    def download_pipeline_models(self, components: Optional[List[str]] = None) -> bool:
        """下载Pipeline模式模型"""
        logger.info("🚀 开始下载Pipeline模式模型...")
        
        config = self.model_configs["pipeline_models"]
        repo_id = config["repo_id"]
        
        if components is None:
            components = list(config["components"].keys())
        
        try:
            # 收集所有需要下载的模式
            all_patterns = []
            for component in components:
                if component in config["components"]:
                    patterns = config["components"][component]["patterns"]
                    all_patterns.extend(patterns)
                    logger.info(f"  📦 {config['components'][component]['description']}")
            
            logger.info(f"从 {repo_id} 下载模型...")
            
            # 下载模型
            local_dir = snapshot_download(
                repo_id=repo_id,
                allow_patterns=all_patterns,
                local_dir=str(self.models_dir),
                cache_dir="/tmp/hf_cache",
                resume_download=True,
                local_files_only=False
            )
            
            logger.success(f"✅ Pipeline模型下载完成: {local_dir}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Pipeline模型下载失败: {e}")
            return False
    
    def download_vlm_models(self) -> bool:
        """下载VLM模式模型"""
        logger.info("🤖 开始下载VLM多模态大模型...")
        
        config = self.model_configs["vlm_models"]
        repo_id = config["repo_id"]
        
        try:
            # VLM模型下载到专用目录
            vlm_dir = self.models_dir / "vlm"
            vlm_dir.mkdir(exist_ok=True)
            
            logger.info(f"从 {repo_id} 下载VLM模型...")
            logger.info(f"  🧠 {config['description']}")
            
            # 下载完整VLM模型
            local_dir = snapshot_download(
                repo_id=repo_id,
                local_dir=str(vlm_dir),
                cache_dir="/tmp/hf_cache",
                resume_download=True,
                local_files_only=False
            )
            
            logger.success(f"✅ VLM模型下载完成: {local_dir}")
            return True
            
        except Exception as e:
            logger.error(f"❌ VLM模型下载失败: {e}")
            return False
    
    def download_layoutreader_model(self) -> bool:
        """下载LayoutReader模型"""
        logger.info("📖 开始下载LayoutReader模型...")
        
        config = self.model_configs["layoutreader"]
        repo_id = config["repo_id"]
        
        try:
            logger.info(f"从 {repo_id} 下载LayoutReader...")
            logger.info(f"  📚 {config['description']}")
            
            # 收集所有模式
            all_patterns = []
            for component in config["components"].values():
                all_patterns.extend(component["patterns"])
            
            # 下载LayoutReader模型
            local_dir = snapshot_download(
                repo_id=repo_id,
                allow_patterns=all_patterns,
                local_dir=str(self.layoutreader_dir),
                cache_dir="/tmp/hf_cache",
                resume_download=True,
                local_files_only=False
            )
            
            logger.success(f"✅ LayoutReader模型下载完成: {local_dir}")
            return True
            
        except Exception as e:
            logger.error(f"❌ LayoutReader模型下载失败: {e}")
            return False
    
    def download_essential_models(self) -> bool:
        """下载核心必需模型（用于Docker构建）"""
        logger.info("⚡ 下载核心必需模型...")
        
        # 只下载最关键的组件
        essential_components = ["layout", "ocr", "formula_detection"]
        
        success = True
        success &= self.download_pipeline_models(essential_components)
        success &= self.download_layoutreader_model()
        
        return success
    
    def download_all_models(self) -> bool:
        """下载所有模型"""
        logger.info("🌟 下载完整功能模型集...")
        
        success = True
        success &= self.download_pipeline_models()
        success &= self.download_vlm_models()
        success &= self.download_layoutreader_model()
        
        return success
    
    def cleanup_cache(self):
        """清理下载缓存"""
        logger.info("🧹 清理下载缓存...")
        import shutil
        cache_dir = Path("/tmp/hf_cache")
        if cache_dir.exists():
            shutil.rmtree(cache_dir, ignore_errors=True)
            logger.info("✅ 缓存清理完成")
    
    def verify_models(self) -> Dict[str, bool]:
        """验证模型完整性"""
        logger.info("🔍 验证模型完整性...")
        
        results = {}
        
        # 检查Pipeline模型
        pipeline_paths = {
            "layout": self.models_dir / "models" / "Layout" / "YOLO",
            "mfd": self.models_dir / "models" / "MFD" / "YOLO", 
            "mfr": self.models_dir / "models" / "MFR",
            "ocr": self.models_dir / "models" / "OCR" / "paddleocr_torch",
            "table": self.models_dir / "models" / "TabRec" / "SlanetPlus"
        }
        
        for name, path in pipeline_paths.items():
            exists = path.exists() and any(path.iterdir()) if path.exists() else False
            results[f"pipeline_{name}"] = exists
            status = "✅" if exists else "❌"
            logger.info(f"  {status} Pipeline {name}: {path}")
        
        # 检查VLM模型
        vlm_path = self.models_dir / "vlm"
        vlm_exists = vlm_path.exists() and any(vlm_path.iterdir()) if vlm_path.exists() else False
        results["vlm"] = vlm_exists
        status = "✅" if vlm_exists else "❌"
        logger.info(f"  {status} VLM模型: {vlm_path}")
        
        # 检查LayoutReader
        lr_exists = self.layoutreader_dir.exists() and any(self.layoutreader_dir.iterdir()) if self.layoutreader_dir.exists() else False
        results["layoutreader"] = lr_exists
        status = "✅" if lr_exists else "❌"
        logger.info(f"  {status} LayoutReader: {self.layoutreader_dir}")
        
        return results
    
    def generate_model_info(self) -> Dict:
        """生成模型信息摘要"""
        info = {
            "model_source": self.model_source,
            "models_dir": str(self.models_dir),
            "layoutreader_dir": str(self.layoutreader_dir),
            "verification": self.verify_models(),
            "configs": self.model_configs
        }
        
        # 保存模型信息
        info_file = self.models_dir / "model_info.json"
        with open(info_file, 'w', encoding='utf-8') as f:
            json.dump(info, f, indent=2, ensure_ascii=False)
        
        logger.info(f"📄 模型信息已保存: {info_file}")
        return info

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="MinerU 全功能版模型下载器")
    parser.add_argument(
        "--mode", 
        choices=["essential", "pipeline", "vlm", "all"], 
        default="all",
        help="下载模式：essential(核心), pipeline(管道), vlm(多模态), all(全部)"
    )
    parser.add_argument(
        "--source",
        choices=["huggingface", "modelscope"],
        default=os.getenv("MINERU_MODEL_SOURCE", "huggingface"),
        help="模型源"
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="只验证模型完整性，不下载"
    )
    parser.add_argument(
        "--cleanup",
        action="store_true", 
        help="下载后清理缓存"
    )
    
    args = parser.parse_args()
    
    logger.info("🎯 MinerU 全功能版模型下载器")
    logger.info(f"模式: {args.mode} | 源: {args.source}")
    
    # 设置模型源环境变量
    os.environ["MINERU_MODEL_SOURCE"] = args.source
    
    # 创建下载器
    downloader = ModelDownloader(model_source=args.source)
    
    # 如果只是验证
    if args.verify:
        results = downloader.verify_models()
        all_good = all(results.values())
        logger.info(f"验证结果: {'✅ 全部正常' if all_good else '❌ 存在问题'}")
        return 0 if all_good else 1
    
    # 执行下载
    success = False
    
    try:
        if args.mode == "essential":
            success = downloader.download_essential_models()
        elif args.mode == "pipeline":
            success = downloader.download_pipeline_models()
        elif args.mode == "vlm":
            success = downloader.download_vlm_models()
        elif args.mode == "all":
            success = downloader.download_all_models()
        
        if success:
            logger.success("🎉 模型下载完成！")
            
            # 生成模型信息
            downloader.generate_model_info()
            
            # 清理缓存
            if args.cleanup:
                downloader.cleanup_cache()
        else:
            logger.error("💥 模型下载失败！")
            return 1
            
    except KeyboardInterrupt:
        logger.warning("⚠️  下载被用户中断")
        return 1
    except Exception as e:
        logger.error(f"💥 下载过程出错: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())