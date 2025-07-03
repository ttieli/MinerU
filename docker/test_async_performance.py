#!/usr/bin/env python3
"""
MinerU Docker异步性能测试脚本

测试异步升级后的Docker服务并发处理能力
"""

import asyncio
import aiohttp
import time
import json
import os
from pathlib import Path

# 测试配置
TEST_CONFIG = {
    "simple_api": "http://localhost:8000",  # 简化版API
    "full_api": "http://localhost:8001",    # 完整版API
    "concurrent_requests": 3,               # 并发请求数
    "test_file": "demo/pdfs/demo1.pdf"      # 测试文件
}

async def test_single_request(session: aiohttp.ClientSession, api_url: str, test_file: str, request_id: int):
    """测试单个请求"""
    start_time = time.time()
    
    try:
        # 检查测试文件是否存在
        if not os.path.exists(test_file):
            return {
                "request_id": request_id,
                "status": "error",
                "error": f"测试文件不存在: {test_file}",
                "duration": 0
            }
        
        # 准备表单数据
        with open(test_file, 'rb') as f:
            data = aiohttp.FormData()
            data.add_field('file', f, filename=os.path.basename(test_file))
            data.add_field('parse_method', 'auto')
            data.add_field('return_content_list', 'false')
            data.add_field('return_images', 'false')
            
            print(f"🚀 请求 {request_id}: 开始发送到 {api_url}")
            
            async with session.post(f"{api_url}/file_parse", data=data, timeout=300) as response:
                result = await response.json()
                end_time = time.time()
                duration = end_time - start_time
                
                if response.status == 200:
                    md_length = len(result.get('md_content', ''))
                    print(f"✅ 请求 {request_id}: 成功完成，耗时 {duration:.2f}秒，内容长度 {md_length}")
                    return {
                        "request_id": request_id,
                        "status": "success",
                        "duration": duration,
                        "content_length": md_length,
                        "api_url": api_url
                    }
                else:
                    print(f"❌ 请求 {request_id}: 失败，状态码 {response.status}")
                    return {
                        "request_id": request_id,
                        "status": "error",
                        "error": f"HTTP {response.status}",
                        "duration": duration
                    }
                    
    except asyncio.TimeoutError:
        duration = time.time() - start_time
        print(f"⏰ 请求 {request_id}: 超时，耗时 {duration:.2f}秒")
        return {
            "request_id": request_id,
            "status": "timeout",
            "duration": duration
        }
    except Exception as e:
        duration = time.time() - start_time
        print(f"💥 请求 {request_id}: 异常，{str(e)}")
        return {
            "request_id": request_id,
            "status": "error",
            "error": str(e),
            "duration": duration
        }

async def check_service_status(session: aiohttp.ClientSession, api_url: str):
    """检查服务状态"""
    try:
        # 检查健康状态
        async with session.get(f"{api_url}/health", timeout=10) as response:
            if response.status == 200:
                health_data = await response.json()
                print(f"🟢 {api_url} 健康检查: {health_data}")
            else:
                print(f"🔴 {api_url} 健康检查失败: HTTP {response.status}")
                return False
        
        # 检查异步状态
        try:
            async with session.get(f"{api_url}/status", timeout=10) as response:
                if response.status == 200:
                    status_data = await response.json()
                    print(f"📊 {api_url} 异步状态: {status_data}")
                else:
                    print(f"⚠️ {api_url} 状态端点不可用")
        except:
            print(f"⚠️ {api_url} 可能还未升级到异步版本")
        
        return True
        
    except Exception as e:
        print(f"🔴 {api_url} 服务不可用: {str(e)}")
        return False

async def test_concurrent_performance(api_url: str, api_name: str):
    """测试并发性能"""
    print(f"\n🧪 开始测试 {api_name} ({api_url}) 的并发性能")
    print(f"📈 并发请求数: {TEST_CONFIG['concurrent_requests']}")
    
    timeout = aiohttp.ClientTimeout(total=600)  # 10分钟超时
    async with aiohttp.ClientSession(timeout=timeout) as session:
        # 检查服务状态
        if not await check_service_status(session, api_url):
            print(f"❌ {api_name} 服务不可用，跳过测试")
            return None
        
        # 创建并发任务
        tasks = []
        overall_start = time.time()
        
        for i in range(TEST_CONFIG['concurrent_requests']):
            task = test_single_request(
                session, 
                api_url, 
                TEST_CONFIG['test_file'], 
                i + 1
            )
            tasks.append(task)
        
        # 并发执行所有请求
        print(f"🚀 同时发送 {len(tasks)} 个并发请求...")
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        overall_duration = time.time() - overall_start
        
        # 统计结果
        successful = sum(1 for r in results if isinstance(r, dict) and r.get('status') == 'success')
        failed = sum(1 for r in results if isinstance(r, dict) and r.get('status') != 'success')
        exceptions = sum(1 for r in results if not isinstance(r, dict))
        
        if successful > 0:
            avg_duration = sum(r['duration'] for r in results if isinstance(r, dict) and r.get('status') == 'success') / successful
            max_duration = max(r['duration'] for r in results if isinstance(r, dict) and r.get('status') == 'success')
            min_duration = min(r['duration'] for r in results if isinstance(r, dict) and r.get('status') == 'success')
        else:
            avg_duration = max_duration = min_duration = 0
        
        # 输出测试结果
        print(f"\n📊 {api_name} 并发测试结果:")
        print(f"   ✅ 成功请求: {successful}/{TEST_CONFIG['concurrent_requests']}")
        print(f"   ❌ 失败请求: {failed}")
        print(f"   💥 异常请求: {exceptions}")
        print(f"   ⏱️  总耗时: {overall_duration:.2f}秒")
        print(f"   ⚡ 平均单请求耗时: {avg_duration:.2f}秒")
        print(f"   🔼 最长单请求耗时: {max_duration:.2f}秒")
        print(f"   🔽 最短单请求耗时: {min_duration:.2f}秒")
        print(f"   🚀 吞吐量: {successful / overall_duration:.2f} 请求/秒")
        
        return {
            "api_name": api_name,
            "api_url": api_url,
            "concurrent_requests": TEST_CONFIG['concurrent_requests'],
            "successful": successful,
            "failed": failed,
            "exceptions": exceptions,
            "overall_duration": overall_duration,
            "avg_duration": avg_duration,
            "max_duration": max_duration,
            "min_duration": min_duration,
            "throughput": successful / overall_duration if overall_duration > 0 else 0,
            "results": results
        }

async def main():
    """主测试函数"""
    print("🎯 MinerU Docker异步性能测试")
    print("=" * 50)
    
    # 检查测试文件
    test_file = TEST_CONFIG['test_file']
    if not os.path.exists(test_file):
        print(f"❌ 测试文件不存在: {test_file}")
        print("💡 请确保在MinerU根目录运行此脚本，并且demo/pdfs/demo1.pdf文件存在")
        return
    
    print(f"📁 使用测试文件: {test_file}")
    
    # 测试简化版API
    simple_result = await test_concurrent_performance(
        TEST_CONFIG['simple_api'], 
        "简化版API (8000端口)"
    )
    
    # 测试完整版API
    full_result = await test_concurrent_performance(
        TEST_CONFIG['full_api'], 
        "完整版API (8001端口)"
    )
    
    # 输出对比结果
    print("\n🆚 性能对比总结:")
    print("=" * 50)
    
    if simple_result and full_result:
        print(f"简化版 vs 完整版:")
        print(f"  成功率: {simple_result['successful']}/{simple_result['concurrent_requests']} vs {full_result['successful']}/{full_result['concurrent_requests']}")
        print(f"  平均耗时: {simple_result['avg_duration']:.2f}s vs {full_result['avg_duration']:.2f}s")
        print(f"  吞吐量: {simple_result['throughput']:.2f} vs {full_result['throughput']:.2f} 请求/秒")
        
        # 性能提升计算
        if simple_result['throughput'] > 0:
            improvement = (simple_result['throughput'] / TEST_CONFIG['concurrent_requests']) * 100
            print(f"  并发效率: {improvement:.1f}% (相比串行处理)")
    
    elif simple_result:
        print(f"✅ 简化版测试完成，完整版不可用")
        improvement = (simple_result['throughput'] / TEST_CONFIG['concurrent_requests']) * 100
        print(f"  并发效率: {improvement:.1f}% (相比串行处理)")
    
    elif full_result:
        print(f"✅ 完整版测试完成，简化版不可用")
        improvement = (full_result['throughput'] / TEST_CONFIG['concurrent_requests']) * 100
        print(f"  并发效率: {improvement:.1f}% (相比串行处理)")
    
    else:
        print("❌ 所有服务都不可用")
    
    print("\n🎉 测试完成！")
    print("💡 提示: 如果看到并发效率接近100%，说明异步升级成功！")

if __name__ == "__main__":
    asyncio.run(main())