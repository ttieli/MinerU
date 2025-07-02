#!/usr/bin/env python3
"""
MinerU 完整部署验证脚本
测试从零开始的完整构建和部署流程
"""

import subprocess
import time
import requests
import json
from datetime import datetime

class FullDeploymentTest:
    def __init__(self):
        self.results = {
            "test_time": datetime.now().isoformat(),
            "phases": {},
            "overall_status": "pending"
        }
        
    def run_command(self, command, description, timeout=300):
        """运行命令并记录结果"""
        print(f"\n🔄 {description}")
        print(f"命令: {command}")
        
        start_time = time.time()
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True, 
                timeout=timeout,
                cwd="/Users/tieli/Library/Mobile Documents/com~apple~CloudDocs/Project/MinerU"
            )
            
            duration = time.time() - start_time
            
            if result.returncode == 0:
                print(f"✅ 成功 ({duration:.1f}秒)")
                return {
                    "status": "success",
                    "duration": duration,
                    "stdout": result.stdout,
                    "stderr": result.stderr
                }
            else:
                print(f"❌ 失败 ({duration:.1f}秒)")
                print(f"错误: {result.stderr}")
                return {
                    "status": "failed",
                    "duration": duration,
                    "stdout": result.stdout,
                    "stderr": result.stderr
                }
                
        except subprocess.TimeoutExpired:
            print(f"⏰ 超时 ({timeout}秒)")
            return {
                "status": "timeout",
                "duration": timeout,
                "error": "Command timed out"
            }
        except Exception as e:
            print(f"❌ 异常: {e}")
            return {
                "status": "error",
                "duration": 0,
                "error": str(e)
            }
    
    def test_health(self, url, version_name):
        """测试服务健康状态"""
        try:
            response = requests.get(f"{url}/health", timeout=10)
            if response.status_code == 200:
                health_data = response.json()
                print(f"✅ {version_name} 健康检查通过: {health_data}")
                return True
            else:
                print(f"❌ {version_name} 健康检查失败: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ {version_name} 连接失败: {e}")
            return False
    
    def test_parsing(self, url, version_name):
        """测试PDF解析功能"""
        print(f"\n🔄 测试{version_name}解析功能...")
        start_time = time.time()
        
        try:
            with open('projects/gradio_app/examples/academic_paper_formula.pdf', 'rb') as f:
                files = {'file': ('test.pdf', f, 'application/pdf')}
                data = {'parse_method': 'auto', 'is_json_md_dump': 'false'}
                
                response = requests.post(f"{url}/file_parse", files=files, data=data, timeout=120)
                
                processing_time = time.time() - start_time
                
                if response.status_code == 200:
                    result = response.json()
                    md_content = result.get('md_content', '')
                    
                    print(f"✅ {version_name} 解析成功")
                    print(f"⏱️ 处理时间: {processing_time:.2f}秒")
                    print(f"📄 内容长度: {len(md_content)} 字符")
                    
                    # 检查内容特征
                    features = {
                        "latex_formulas": md_content.count('$'),
                        "has_sections": '#' in md_content,
                        "content_length": len(md_content)
                    }
                    
                    return {
                        "status": "success",
                        "processing_time": processing_time,
                        "features": features
                    }
                else:
                    print(f"❌ {version_name} 解析失败: {response.status_code}")
                    return {
                        "status": "failed",
                        "error": response.text,
                        "processing_time": processing_time
                    }
                    
        except Exception as e:
            processing_time = time.time() - start_time
            print(f"❌ {version_name} 测试出错: {e}")
            return {
                "status": "error",
                "error": str(e),
                "processing_time": processing_time
            }
    
    def run_full_test(self):
        """运行完整的部署测试"""
        print("🚀 开始MinerU完整部署验证测试")
        print("=" * 60)
        
        # 阶段1: 检查当前状态
        print("\n📋 阶段1: 检查当前状态")
        self.results["phases"]["check_status"] = {}
        
        # 检查Docker是否运行
        docker_check = self.run_command("docker info", "检查Docker状态", 30)
        self.results["phases"]["check_status"]["docker"] = docker_check
        
        if docker_check["status"] != "success":
            self.results["overall_status"] = "failed"
            print("❌ Docker未运行，测试终止")
            return self.results
        
        # 阶段2: 清理现有容器
        print("\n🧹 阶段2: 清理现有容器")
        self.results["phases"]["cleanup"] = {}
        
        # 停止可能存在的容器
        cleanup_commands = [
            ("docker compose -f docker/m1-mac-full/docker-compose-fixed.yml down", "停止完整版容器"),
            ("docker compose -f docker/m1-mac-full/docker-compose-efficient.yml down", "停止旧完整版容器"),
        ]
        
        for cmd, desc in cleanup_commands:
            result = self.run_command(cmd, desc, 60)
            self.results["phases"]["cleanup"][desc] = result
        
        # 阶段3: 构建镜像
        print("\n🏗️ 阶段3: 构建镜像")
        self.results["phases"]["build"] = {}
        
        # 构建完整版镜像
        build_result = self.run_command(
            "docker compose -f docker/m1-mac-full/docker-compose-fixed.yml build",
            "构建完整版镜像",
            1200  # 20分钟超时
        )
        self.results["phases"]["build"]["full_version"] = build_result
        
        if build_result["status"] != "success":
            self.results["overall_status"] = "failed"
            print("❌ 镜像构建失败，测试终止")
            return self.results
        
        # 阶段4: 启动服务
        print("\n🚀 阶段4: 启动服务")
        self.results["phases"]["startup"] = {}
        
        # 启动完整版
        startup_result = self.run_command(
            "docker compose -f docker/m1-mac-full/docker-compose-fixed.yml up -d",
            "启动完整版服务",
            120
        )
        self.results["phases"]["startup"]["full_version"] = startup_result
        
        if startup_result["status"] != "success":
            self.results["overall_status"] = "failed"
            print("❌ 服务启动失败，测试终止")
            return self.results
        
        # 等待服务就绪
        print("\n⏳ 等待服务启动...")
        time.sleep(60)
        
        # 阶段5: 健康检查
        print("\n🏥 阶段5: 健康检查")
        self.results["phases"]["health_check"] = {}
        
        # 检查简化版（应该已经运行）
        simplified_health = self.test_health("http://localhost:8000", "简化版")
        self.results["phases"]["health_check"]["simplified"] = simplified_health
        
        # 检查完整版
        full_health = self.test_health("http://localhost:8001", "完整版")
        self.results["phases"]["health_check"]["full"] = full_health
        
        if not (simplified_health and full_health):
            self.results["overall_status"] = "partial"
            print("⚠️ 部分服务健康检查失败")
        
        # 阶段6: 功能测试
        print("\n🧪 阶段6: 功能测试")
        self.results["phases"]["functionality"] = {}
        
        if simplified_health:
            simplified_test = self.test_parsing("http://localhost:8000", "简化版")
            self.results["phases"]["functionality"]["simplified"] = simplified_test
        
        if full_health:
            full_test = self.test_parsing("http://localhost:8001", "完整版")
            self.results["phases"]["functionality"]["full"] = full_test
        
        # 阶段7: 对比分析
        print("\n📊 阶段7: 对比分析")
        if simplified_health and full_health:
            try:
                simplified_result = self.results["phases"]["functionality"]["simplified"]
                full_result = self.results["phases"]["functionality"]["full"]
                
                if simplified_result["status"] == "success" and full_result["status"] == "success":
                    comparison = {
                        "time_difference": full_result["processing_time"] - simplified_result["processing_time"],
                        "content_enhancement": full_result["features"]["content_length"] / simplified_result["features"]["content_length"],
                        "formula_count_full": full_result["features"]["latex_formulas"],
                        "formula_count_simplified": simplified_result["features"]["latex_formulas"]
                    }
                    self.results["phases"]["comparison"] = comparison
                    
                    print(f"⏱️ 时间差异: +{comparison['time_difference']:.2f}秒")
                    print(f"📈 内容增强: {comparison['content_enhancement']:.2f}x")
                    print(f"🧮 公式识别: 完整版{comparison['formula_count_full']} vs 简化版{comparison['formula_count_simplified']}")
                    
            except Exception as e:
                print(f"❌ 对比分析失败: {e}")
        
        # 最终状态
        if all([
            docker_check["status"] == "success",
            build_result["status"] == "success",
            startup_result["status"] == "success",
            simplified_health,
            full_health
        ]):
            self.results["overall_status"] = "success"
            print("\n🎉 完整部署验证测试成功！")
        else:
            self.results["overall_status"] = "partial"
            print("\n⚠️ 部分测试成功，存在问题")
        
        return self.results

if __name__ == "__main__":
    tester = FullDeploymentTest()
    results = tester.run_full_test()
    
    # 保存结果
    with open("deployment_test_results.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(f"\n📁 详细结果已保存到: deployment_test_results.json")
    print(f"🏁 总体状态: {results['overall_status']}")