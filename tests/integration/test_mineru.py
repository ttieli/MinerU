#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MinerU Docker API 测试程序
用于自动检测本地 Docker 运行的 MinerU 服务可用性
并上传 PDF 文件测试解析接口，将结果保存到 test_output/
"""

import os
import sys
import shutil
import json
from pathlib import Path
from datetime import datetime
import requests
import glob

API_BASE = os.environ.get("MINERU_API_BASE", "http://localhost:8000")
OUTPUT_DIR = Path("test_output")
LOCAL_OUTPUT_ROOT = Path("docker/m1-mac/output")  # docker-compose.yml 挂载的实际路径

# 1. 清理输出目录
def setup_output_dir():
    if OUTPUT_DIR.exists():
        print(f"🗑️  删除已存在的输出目录: {OUTPUT_DIR}")
        shutil.rmtree(OUTPUT_DIR)
    OUTPUT_DIR.mkdir(exist_ok=True)
    print(f"📁 创建输出目录: {OUTPUT_DIR}")

# 2. 查找测试 PDF 文件
def find_test_pdf():
    test_paths = [
        "demo/pdfs/demo1.pdf",
        "demo/pdfs/demo2.pdf",
        "demo/pdfs/demo3.pdf",
        "demo/pdfs/small_ocr.pdf"
    ]
    for pdf_path in test_paths:
        if os.path.exists(pdf_path):
            print(f"✅ 找到测试文件: {pdf_path}")
            return pdf_path
    print("❌ 未找到测试 PDF 文件")
    return None

# 3. 复制产物到 test_output/
def copy_outputs_to_test_output(pdf_path):
    file_stem = Path(pdf_path).stem
    src_dir = LOCAL_OUTPUT_ROOT / file_stem
    if not src_dir.exists():
        print(f"⚠️  未找到产物目录: {src_dir}")
        return False
    print(f"📂 复制解析产物: {src_dir} -> {OUTPUT_DIR}")
    # 递归复制所有文件和子目录
    for root, dirs, files in os.walk(src_dir):
        rel_root = os.path.relpath(root, src_dir)
        target_root = OUTPUT_DIR / rel_root if rel_root != '.' else OUTPUT_DIR
        os.makedirs(target_root, exist_ok=True)
        for file in files:
            src_file = Path(root) / file
            dst_file = target_root / file
            shutil.copy2(src_file, dst_file)
    print(f"✅ 产物已复制到: {OUTPUT_DIR}")
    return True

# 4. 测试 API 接口
def test_api():
    report = {
        "timestamp": datetime.now().isoformat(),
        "api_base": API_BASE,
        "results": {},
        "system_info": {
            "python_version": sys.version,
            "platform": sys.platform,
            "cwd": os.getcwd()
        }
    }
    session = requests.Session()
    # 4.1 测试 /health
    try:
        url = f"{API_BASE}/health"
        resp = session.get(url, timeout=10)
        report["results"]["health"] = {
            "status_code": resp.status_code,
            "response": resp.json() if resp.headers.get('content-type','').startswith('application/json') else resp.text
        }
        print(f"/health: {resp.status_code} {resp.text}")
    except Exception as e:
        report["results"]["health"] = {"error": str(e)}
        print(f"/health 失败: {e}")
    # 4.2 测试 /docs
    try:
        url = f"{API_BASE}/docs"
        resp = session.get(url, timeout=10)
        report["results"]["docs"] = {
            "status_code": resp.status_code,
            "content_length": len(resp.content)
        }
        print(f"/docs: {resp.status_code} (length={len(resp.content)})")
    except Exception as e:
        report["results"]["docs"] = {"error": str(e)}
        print(f"/docs 失败: {e}")
    # 4.3 只测试 /file_parse
    pdf_path = find_test_pdf()
    parse_result = None
    url = f"{API_BASE}/file_parse"
    if not pdf_path:
        report["results"]["/file_parse"] = {"error": "未找到测试 PDF 文件"}
    else:
        try:
            with open(pdf_path, "rb") as f:
                files = {"file": (os.path.basename(pdf_path), f, "application/pdf")}
                data = {"is_json_md_dump": "true"}
                print(f"尝试上传 {pdf_path} 到 {url} (is_json_md_dump=True)")
                resp = session.post(url, files=files, data=data, timeout=300)
                try:
                    resp_json = resp.json()
                except Exception:
                    resp_json = resp.text
                report["results"]["/file_parse"] = {
                    "status_code": resp.status_code,
                    "response": resp_json
                }
                if resp.status_code == 200:
                    parse_result = resp_json
                print(f"/file_parse: {resp.status_code}")
        except Exception as e:
            report["results"]["/file_parse"] = {"error": str(e)}
            print(f"/file_parse 失败: {e}")
        # 复制产物
        copy_outputs_to_test_output(pdf_path)
    # 保存解析结果
    if parse_result:
        with open(OUTPUT_DIR / "parse_result.json", "w", encoding="utf-8") as f:
            json.dump(parse_result, f, ensure_ascii=False, indent=2)
        print(f"✅ 解析结果已保存: {OUTPUT_DIR / 'parse_result.json'}")
    # 保存测试报告
    with open(OUTPUT_DIR / "test_report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print(f"📊 测试报告已保存: {OUTPUT_DIR / 'test_report.json'}")

if __name__ == "__main__":
    print("🚀 MinerU Docker API 测试程序")
    print(f"目标 API: {API_BASE}")
    setup_output_dir()
    test_api() 