#!/usr/bin/env python3
"""
MinerU 版本对比测试脚本
对同一PDF文档使用简化版和完整版进行解析，并生成对比报告
"""

import json
import time
import requests
import os
from datetime import datetime
from typing import Dict, Any
import difflib
import hashlib

class MinerUVersionComparison:
    def __init__(self):
        self.simplified_url = "http://localhost:8000"
        self.full_url = "http://localhost:8001"
        self.test_pdf_path = "projects/gradio_app/examples/academic_paper_formula.pdf"
        self.output_dir = "version_comparison_results"
        
        # 创建输出目录
        os.makedirs(self.output_dir, exist_ok=True)
        
    def check_service_health(self, url: str, version_name: str) -> bool:
        """检查服务健康状态"""
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
    
    def parse_pdf(self, url: str, version_name: str) -> Dict[str, Any]:
        """使用指定版本解析PDF"""
        print(f"\n🔄 使用{version_name}解析PDF...")
        
        start_time = time.time()
        
        try:
            with open(self.test_pdf_path, 'rb') as f:
                files = {'file': (os.path.basename(self.test_pdf_path), f, 'application/pdf')}
                data = {
                    'parse_method': 'auto',
                    'is_json_md_dump': 'false',
                    'return_layout': 'true',
                    'return_info': 'true',
                    'return_content_list': 'true',
                    'return_images': 'false'
                }
                
                response = requests.post(
                    f"{url}/file_parse",
                    files=files,
                    data=data,
                    timeout=300  # 5分钟超时
                )
                
                end_time = time.time()
                processing_time = end_time - start_time
                
                if response.status_code == 200:
                    result = response.json()
                    result['_meta'] = {
                        'version': version_name,
                        'processing_time': processing_time,
                        'timestamp': datetime.now().isoformat(),
                        'status': 'success'
                    }
                    print(f"✅ {version_name} 解析成功，耗时: {processing_time:.2f}秒")
                    return result
                else:
                    print(f"❌ {version_name} 解析失败: {response.status_code}")
                    print(f"错误信息: {response.text}")
                    return {
                        '_meta': {
                            'version': version_name,
                            'processing_time': processing_time,
                            'timestamp': datetime.now().isoformat(),
                            'status': 'failed',
                            'error': response.text
                        }
                    }
                    
        except Exception as e:
            end_time = time.time()
            processing_time = end_time - start_time
            print(f"❌ {version_name} 解析出错: {e}")
            return {
                '_meta': {
                    'version': version_name,
                    'processing_time': processing_time,
                    'timestamp': datetime.now().isoformat(),
                    'status': 'error',
                    'error': str(e)
                }
            }
    
    def calculate_text_similarity(self, text1: str, text2: str) -> float:
        """计算文本相似度"""
        matcher = difflib.SequenceMatcher(None, text1, text2)
        return matcher.ratio()
    
    def analyze_differences(self, simplified_result: Dict, full_result: Dict) -> Dict[str, Any]:
        """分析两个版本的差异"""
        analysis = {
            'performance': {},
            'content': {},
            'features': {},
            'quality': {}
        }
        
        # 性能对比
        if '_meta' in simplified_result and '_meta' in full_result:
            analysis['performance'] = {
                'simplified_time': simplified_result['_meta'].get('processing_time', 0),
                'full_time': full_result['_meta'].get('processing_time', 0),
                'time_difference': full_result['_meta'].get('processing_time', 0) - 
                                simplified_result['_meta'].get('processing_time', 0)
            }
        
        # 内容对比
        simplified_md = simplified_result.get('md_content', '')
        full_md = full_result.get('md_content', '')
        
        analysis['content'] = {
            'simplified_length': len(simplified_md),
            'full_length': len(full_md),
            'length_difference': len(full_md) - len(simplified_md),
            'similarity': self.calculate_text_similarity(simplified_md, full_md),
            'simplified_lines': len(simplified_md.split('\n')),
            'full_lines': len(full_md.split('\n'))
        }
        
        # 功能对比
        simplified_result_data = simplified_result.get('result', {})
        full_result_data = full_result.get('result', {})
        
        analysis['features'] = {
            'simplified_has_layout': 'layout' in simplified_result,
            'full_has_layout': 'layout' in full_result,
            'simplified_blocks_count': len(simplified_result_data.get('pdf_info', [{}])[0].get('preproc_blocks', [])) if simplified_result_data.get('pdf_info') else 0,
            'full_blocks_count': len(full_result_data.get('pdf_info', [{}])[0].get('preproc_blocks', [])) if full_result_data.get('pdf_info') else 0
        }
        
        # 质量评估
        analysis['quality'] = {
            'simplified_has_errors': simplified_result['_meta'].get('status') != 'success',
            'full_has_errors': full_result['_meta'].get('status') != 'success',
            'content_enhancement_ratio': len(full_md) / len(simplified_md) if len(simplified_md) > 0 else 0
        }
        
        return analysis
    
    def generate_comparison_report(self, simplified_result: Dict, full_result: Dict, analysis: Dict) -> str:
        """生成对比报告"""
        report = f"""# MinerU 版本对比报告

## 📋 测试信息
- **测试文档**: {self.test_pdf_path}
- **测试时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **文档大小**: {os.path.getsize(self.test_pdf_path) / 1024:.2f} KB

## ⚡ 性能对比

| 指标 | 简化版 | 完整版 | 差异 |
|------|--------|--------|------|
| 处理时间 | {analysis['performance'].get('simplified_time', 0):.2f}秒 | {analysis['performance'].get('full_time', 0):.2f}秒 | {analysis['performance'].get('time_difference', 0):+.2f}秒 |
| 状态 | {simplified_result['_meta'].get('status', 'unknown')} | {full_result['_meta'].get('status', 'unknown')} | - |

## 📄 内容对比

| 指标 | 简化版 | 完整版 | 差异 |
|------|--------|--------|------|
| Markdown长度 | {analysis['content']['simplified_length']:,} 字符 | {analysis['content']['full_length']:,} 字符 | {analysis['content']['length_difference']:+,} 字符 |
| 行数 | {analysis['content']['simplified_lines']:,} 行 | {analysis['content']['full_lines']:,} 行 | {analysis['content']['full_lines'] - analysis['content']['simplified_lines']:+,} 行 |
| 内容相似度 | - | - | {analysis['content']['similarity']:.2%} |

## 🔧 功能对比

| 功能 | 简化版 | 完整版 |
|------|--------|--------|
| 布局分析 | {'✅' if analysis['features']['simplified_has_layout'] else '❌'} | {'✅' if analysis['features']['full_has_layout'] else '❌'} |
| 识别块数量 | {analysis['features']['simplified_blocks_count']} | {analysis['features']['full_blocks_count']} |

## 📊 质量评估

| 评估项 | 简化版 | 完整版 |
|--------|--------|--------|
| 解析成功 | {'❌' if analysis['quality']['simplified_has_errors'] else '✅'} | {'❌' if analysis['quality']['full_has_errors'] else '✅'} |
| 内容增强率 | - | {analysis['quality']['content_enhancement_ratio']:.2f}x |

## 📝 主要差异

### 处理时间
- 完整版比简化版{'慢' if analysis['performance'].get('time_difference', 0) > 0 else '快'} {abs(analysis['performance'].get('time_difference', 0)):.2f}秒

### 内容质量
- 完整版输出内容比简化版{'多' if analysis['content']['length_difference'] > 0 else '少'} {abs(analysis['content']['length_difference']):,} 个字符
- 内容相似度: {analysis['content']['similarity']:.2%}

### 功能差异
- 完整版识别到 {analysis['features']['full_blocks_count']} 个文档块
- 简化版识别到 {analysis['features']['simplified_blocks_count']} 个文档块

## 🎯 使用建议

"""
        
        # 根据分析结果给出建议
        if analysis['performance'].get('time_difference', 0) < 10:
            report += "- **性能**: 两版本处理速度相近，可根据功能需求选择\n"
        elif analysis['performance'].get('time_difference', 0) < 30:
            report += "- **性能**: 完整版处理时间稍长，适合对精度要求高的场景\n"
        else:
            report += "- **性能**: 完整版处理时间明显较长，建议日常使用简化版\n"
        
        if analysis['content']['similarity'] > 0.9:
            report += "- **内容**: 两版本输出高度相似，简化版已能满足大部分需求\n"
        elif analysis['content']['similarity'] > 0.7:
            report += "- **内容**: 完整版在内容识别上有一定优势\n"
        else:
            report += "- **内容**: 完整版在内容识别上有显著优势，建议专业场景使用\n"
        
        if analysis['features']['full_blocks_count'] > analysis['features']['simplified_blocks_count']:
            report += "- **功能**: 完整版识别更多文档结构，适合复杂文档分析\n"
        
        report += f"""
## 📁 详细结果文件

- 简化版结果: `{self.output_dir}/simplified_result.json`
- 完整版结果: `{self.output_dir}/full_result.json`
- 简化版Markdown: `{self.output_dir}/simplified_content.md`
- 完整版Markdown: `{self.output_dir}/full_content.md`
- 分析数据: `{self.output_dir}/analysis.json`

---
*报告生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*
"""
        
        return report
    
    def run_comparison(self):
        """运行完整的对比测试"""
        print("🚀 开始MinerU版本对比测试")
        print("=" * 50)
        
        # 检查服务健康状态
        if not self.check_service_health(self.simplified_url, "简化版"):
            return False
        
        if not self.check_service_health(self.full_url, "完整版"):
            return False
        
        # 检查测试文件
        if not os.path.exists(self.test_pdf_path):
            print(f"❌ 测试文件不存在: {self.test_pdf_path}")
            return False
        
        print(f"📄 测试文档: {self.test_pdf_path}")
        print(f"📁 结果输出目录: {self.output_dir}")
        
        # 解析PDF
        simplified_result = self.parse_pdf(self.simplified_url, "简化版")
        full_result = self.parse_pdf(self.full_url, "完整版")
        
        # 保存详细结果
        with open(f"{self.output_dir}/simplified_result.json", 'w', encoding='utf-8') as f:
            json.dump(simplified_result, f, ensure_ascii=False, indent=2)
        
        with open(f"{self.output_dir}/full_result.json", 'w', encoding='utf-8') as f:
            json.dump(full_result, f, ensure_ascii=False, indent=2)
        
        # 保存Markdown内容
        with open(f"{self.output_dir}/simplified_content.md", 'w', encoding='utf-8') as f:
            f.write(simplified_result.get('md_content', ''))
        
        with open(f"{self.output_dir}/full_content.md", 'w', encoding='utf-8') as f:
            f.write(full_result.get('md_content', ''))
        
        # 分析差异
        analysis = self.analyze_differences(simplified_result, full_result)
        
        # 保存分析数据
        with open(f"{self.output_dir}/analysis.json", 'w', encoding='utf-8') as f:
            json.dump(analysis, f, ensure_ascii=False, indent=2)
        
        # 生成报告
        report = self.generate_comparison_report(simplified_result, full_result, analysis)
        
        # 保存报告
        with open(f"{self.output_dir}/comparison_report.md", 'w', encoding='utf-8') as f:
            f.write(report)
        
        print("\n" + "=" * 50)
        print("✅ 对比测试完成！")
        print(f"📊 查看报告: {self.output_dir}/comparison_report.md")
        
        return True

if __name__ == "__main__":
    comparator = MinerUVersionComparison()
    comparator.run_comparison()