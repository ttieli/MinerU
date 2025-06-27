#!/usr/bin/env python3
"""
MinerU M1 Mac API 测试脚本
"""

import requests
import json
import time
import os
from pathlib import Path

# API配置
API_BASE_URL = "http://localhost:8000"
TEST_FILES_DIR = Path("test_files")

def test_health_check():
    """测试健康检查"""
    print("🔍 测试健康检查...")
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        if response.status_code == 200:
            print("✅ 健康检查通过")
            return True
        else:
            print(f"❌ 健康检查失败: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 健康检查异常: {e}")
        return False

def test_api_docs():
    """测试API文档"""
    print("📚 测试API文档...")
    try:
        response = requests.get(f"{API_BASE_URL}/docs", timeout=10)
        if response.status_code == 200:
            print("✅ API文档可访问")
            return True
        else:
            print(f"❌ API文档不可访问: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ API文档异常: {e}")
        return False

def test_file_upload(file_path):
    """测试文件上传解析"""
    if not os.path.exists(file_path):
        print(f"⚠️  测试文件不存在: {file_path}")
        return False
    
    print(f"📄 测试文件解析: {file_path}")
    try:
        with open(file_path, 'rb') as f:
            files = {'file': f}
            data = {
                'parse_method': 'auto',
                'return_content_list': True,
                'return_info': True
            }
            
            start_time = time.time()
            response = requests.post(
                f"{API_BASE_URL}/file_parse",
                files=files,
                data=data,
                timeout=300  # 5分钟超时
            )
            end_time = time.time()
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ 文件解析成功 (耗时: {end_time - start_time:.2f}秒)")
                print(f"   - MD内容长度: {len(result.get('md_content', ''))}")
                print(f"   - 内容列表项数: {len(result.get('content_list', []))}")
                return True
            else:
                print(f"❌ 文件解析失败: {response.status_code}")
                print(f"   错误信息: {response.text}")
                return False
                
    except Exception as e:
        print(f"❌ 文件解析异常: {e}")
        return False

def test_performance():
    """测试性能"""
    print("⚡ 测试性能指标...")
    
    # 测试内存使用
    try:
        import psutil
        import docker
        
        client = docker.from_env()
        container = client.containers.get("mineru-m1-api")
        stats = container.stats(stream=False)
        
        memory_usage = stats['memory_stats']['usage']
        memory_limit = stats['memory_stats']['limit']
        memory_percent = (memory_usage / memory_limit) * 100
        
        print(f"   - 内存使用: {memory_usage / 1024 / 1024:.2f}MB / {memory_limit / 1024 / 1024:.2f}MB ({memory_percent:.1f}%)")
        
        cpu_percent = stats['cpu_stats']['cpu_usage']['total_usage']
        print(f"   - CPU使用: {cpu_percent}")
        
    except Exception as e:
        print(f"   ⚠️  无法获取性能指标: {e}")

def create_test_files():
    """创建测试文件"""
    TEST_FILES_DIR.mkdir(exist_ok=True)
    
    # 创建测试文本文件
    test_text = """# 测试文档

这是一个测试文档，用于验证MinerU API的功能。

## 主要功能
- PDF解析
- Office文档解析
- 图像OCR识别

## 技术特点
- M1芯片优化
- 低内存占用
- CPU模式运行
"""
    
    with open(TEST_FILES_DIR / "test.txt", "w", encoding="utf-8") as f:
        f.write(test_text)
    
    print(f"📁 测试文件已创建: {TEST_FILES_DIR}")

def main():
    """主测试函数"""
    print("🚀 MinerU M1 Mac API 测试开始\n")
    
    # 创建测试文件
    create_test_files()
    
    # 测试列表
    tests = [
        ("健康检查", test_health_check),
        ("API文档", test_api_docs),
    ]
    
    # 检查测试文件
    test_files = [
        "../../demo/pdfs/demo1.pdf",
        "test_files/test.txt"
    ]
    
    passed = 0
    total = len(tests)
    
    # 运行基础测试
    for test_name, test_func in tests:
        if test_func():
            passed += 1
        print()
    
    # 运行文件测试
    for test_file in test_files:
        if os.path.exists(test_file):
            total += 1
            if test_file_upload(test_file):
                passed += 1
            print()
    
    # 性能测试
    test_performance()
    print()
    
    # 测试结果
    print(f"📊 测试结果: {passed}/{total} 通过")
    
    if passed == total:
        print("🎉 所有测试通过！")
        return 0
    else:
        print("⚠️  部分测试失败，请检查服务状态")
        return 1

if __name__ == "__main__":
    exit(main())