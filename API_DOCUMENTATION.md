# MinerU API 调用详细文档

## 📋 概述

MinerU 提供高性能的PDF文档解析服务，支持简化版和完整版两种配置，通过RESTful API接口提供服务。

### 🌐 服务地址
- **简化版**: `http://localhost:8000` (推荐日常使用)
- **完整版**: `http://localhost:8001` (推荐专业分析)

### 📊 版本对比
| 特性 | 简化版 | 完整版 |
|------|--------|--------|
| **内存需求** | 8GB | 16GB+ |
| **处理速度** | 快 (~7秒) | 慢 (~60秒) |
| **PDF解析** | ✅ | ✅ |
| **OCR识别** | ✅ | ✅ 增强 |
| **表格识别** | 基础 | 高级 |
| **公式识别** | ❌ | ✅ LaTeX |
| **多模态VLM** | ❌ | ✅ |

---

## 🛡️ API端点

### 1. 健康检查

#### `GET /health`

检查服务运行状态。

**请求示例**:
```bash
curl -X GET "http://localhost:8000/health"
```

**响应示例**:
```json
{
  "status": "healthy",
  "service": "mineru-m1",
  "version": "1.1_fixed"
}
```

### 2. 服务信息

#### `GET /`

获取服务基本信息。

**请求示例**:
```bash
curl -X GET "http://localhost:8001/"
```

**响应示例**:
```json
{
  "message": "MinerU API - M1 Mac Full Version",
  "status": "running",
  "version": "2.0.0-full",
  "features": ["PDF解析", "表格识别", "公式识别", "VLM分析"],
  "ports": {"api": 8001, "webui": 3001}
}
```

### 3. 文件解析 (核心接口)

#### `POST /file_parse`

解析PDF/Office/图像文件为JSON和Markdown格式。

**请求参数**:

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `file` | File | 是* | - | 要解析的文件 (与file_path二选一) |
| `file_path` | String | 是* | - | 文件路径 (与file二选一) |
| `parse_method` | String | 否 | "auto" | 解析方法: auto/ocr/txt |
| `is_json_md_dump` | Boolean | 否 | false | 是否保存解析结果到文件 |
| `output_dir` | String | 否 | "output" | 输出目录名称 |
| `return_layout` | Boolean | 否 | false | 是否返回布局信息 |
| `return_info` | Boolean | 否 | false | 是否返回文档信息 |
| `return_content_list` | Boolean | 否 | false | 是否返回内容列表 |
| `return_images` | Boolean | 否 | false | 是否返回Base64编码图片 |

**解析方法说明**:
- `auto`: 自动选择最优解析方式 (推荐)
- `ocr`: 强制使用OCR识别 (适用于扫描版PDF)
- `txt`: 直接提取文本 (适用于纯文本PDF)

---

## 🔧 请求示例

### 基础调用

**cURL**:
```bash
curl -X POST "http://localhost:8000/file_parse" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@document.pdf" \
  -F "parse_method=auto"
```

**Python requests**:
```python
import requests

def parse_pdf_basic(file_path, api_url="http://localhost:8000"):
    """基础PDF解析"""
    with open(file_path, 'rb') as f:
        files = {'file': (file_path, f, 'application/pdf')}
        data = {'parse_method': 'auto'}
        
        response = requests.post(f"{api_url}/file_parse", 
                               files=files, data=data, timeout=300)
        
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"API Error: {response.status_code} - {response.text}")

# 使用示例
result = parse_pdf_basic("document.pdf")
print(f"解析内容长度: {len(result['md_content'])} 字符")
```

### 高级调用 (保存文件 + 返回图片)

**cURL**:
```bash
curl -X POST "http://localhost:8001/file_parse" \
  -F "file=@academic_paper.pdf" \
  -F "parse_method=auto" \
  -F "is_json_md_dump=true" \
  -F "output_dir=research_output" \
  -F "return_images=true" \
  -F "return_layout=true"
```

**Python requests**:
```python
def parse_pdf_advanced(file_path, api_url="http://localhost:8001", save_files=True):
    """高级PDF解析 - 完整版功能"""
    with open(file_path, 'rb') as f:
        files = {'file': (file_path, f, 'application/pdf')}
        data = {
            'parse_method': 'auto',
            'is_json_md_dump': save_files,
            'output_dir': 'advanced_output',
            'return_layout': True,
            'return_images': True,
            'return_info': True
        }
        
        response = requests.post(f"{api_url}/file_parse", 
                               files=files, data=data, timeout=600)
        
        return response.json() if response.status_code == 200 else None

# 使用示例
result = parse_pdf_advanced("research_paper.pdf")
if result:
    print(f"提取公式数量: {result['md_content'].count('$')}")
    print(f"包含图片: {len(result.get('images', {}))}")
```

---

## 📤 响应格式

### 标准响应

```json
{
  "result": {
    "content_list": [
      {
        "type": "text",
        "content": "文档内容...",
        "bbox": [x1, y1, x2, y2],
        "page": 1
      }
    ],
    "layout": {
      "pages": 10,
      "layout_info": {...}
    },
    "metadata": {
      "title": "文档标题",
      "author": "作者",
      "creation_date": "2024-01-01"
    }
  },
  "md_content": "# 文档标题\n\n文档内容..."
}
```

### 简化版响应特点

```json
{
  "result": {
    "content_list": [...],
    "layout": {...}
  },
  "md_content": "解析的Markdown内容",
  "processing_time": 7.14,
  "features": {
    "has_tables": true,
    "has_formulas": false,
    "formula_count": 0
  }
}
```

### 完整版增强响应

```json
{
  "result": {
    "content_list": [...],
    "layout": {...},
    "formulas": [
      {
        "latex": "E = mc^2",
        "bbox": [x1, y1, x2, y2],
        "confidence": 0.95
      }
    ],
    "vlm_analysis": {
      "document_type": "academic_paper",
      "quality_score": 0.92,
      "layout_analysis": {...}
    }
  },
  "md_content": "包含LaTeX公式的内容: $E = mc^2$",
  "processing_time": 66.38,
  "features": {
    "has_tables": true,
    "has_formulas": true,
    "formula_count": 76,
    "content_enhancement": 1.21
  }
}
```

### 包含图片的响应

```json
{
  "result": {...},
  "md_content": "...",
  "images": {
    "image1.jpg": "base64_encoded_string...",
    "image2.jpg": "base64_encoded_string..."
  }
}
```

---

## 🐍 Python SDK 封装

### 完整的客户端类

```python
import requests
import json
import time
from typing import Optional, Dict, Any, Union
import base64
import os

class MinerUClient:
    """MinerU API 客户端"""
    
    def __init__(self, base_url: str = "http://localhost:8000", timeout: int = 300):
        """
        初始化客户端
        
        Args:
            base_url: API服务地址
            timeout: 请求超时时间(秒)
        """
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.session = requests.Session()
    
    def health_check(self) -> Dict[str, Any]:
        """检查服务健康状态"""
        response = self.session.get(f"{self.base_url}/health", timeout=10)
        response.raise_for_status()
        return response.json()
    
    def get_service_info(self) -> Dict[str, Any]:
        """获取服务信息"""
        response = self.session.get(f"{self.base_url}/", timeout=10)
        response.raise_for_status()
        return response.json()
    
    def parse_pdf(self, 
                  file_path: str,
                  parse_method: str = "auto",
                  save_files: bool = False,
                  output_dir: str = "output",
                  return_images: bool = False,
                  return_layout: bool = False,
                  return_info: bool = False) -> Dict[str, Any]:
        """
        解析PDF文件
        
        Args:
            file_path: PDF文件路径
            parse_method: 解析方法 (auto/ocr/txt)
            save_files: 是否保存解析结果到文件
            output_dir: 输出目录
            return_images: 是否返回图片
            return_layout: 是否返回布局信息
            return_info: 是否返回文档信息
            
        Returns:
            解析结果字典
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"文件不存在: {file_path}")
        
        with open(file_path, 'rb') as f:
            files = {'file': (os.path.basename(file_path), f, 'application/pdf')}
            data = {
                'parse_method': parse_method,
                'is_json_md_dump': str(save_files).lower(),
                'output_dir': output_dir,
                'return_images': str(return_images).lower(),
                'return_layout': str(return_layout).lower(),
                'return_info': str(return_info).lower()
            }
            
            start_time = time.time()
            response = self.session.post(f"{self.base_url}/file_parse", 
                                       files=files, data=data, timeout=self.timeout)
            processing_time = time.time() - start_time
            
            if response.status_code == 200:
                result = response.json()
                result['_client_processing_time'] = processing_time
                return result
            else:
                raise Exception(f"API请求失败: {response.status_code} - {response.text}")
    
    def parse_pdf_from_bytes(self,
                           file_bytes: bytes,
                           filename: str,
                           **kwargs) -> Dict[str, Any]:
        """
        从字节数据解析PDF
        
        Args:
            file_bytes: PDF文件字节数据
            filename: 文件名
            **kwargs: 其他参数同parse_pdf方法
        """
        files = {'file': (filename, file_bytes, 'application/pdf')}
        data = {
            'parse_method': kwargs.get('parse_method', 'auto'),
            'is_json_md_dump': str(kwargs.get('save_files', False)).lower(),
            'output_dir': kwargs.get('output_dir', 'output'),
            'return_images': str(kwargs.get('return_images', False)).lower(),
            'return_layout': str(kwargs.get('return_layout', False)).lower(),
            'return_info': str(kwargs.get('return_info', False)).lower()
        }
        
        response = self.session.post(f"{self.base_url}/file_parse", 
                                   files=files, data=data, timeout=self.timeout)
        
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"API请求失败: {response.status_code} - {response.text}")
    
    def extract_markdown(self, file_path: str, **kwargs) -> str:
        """提取Markdown内容"""
        result = self.parse_pdf(file_path, **kwargs)
        return result.get('md_content', '')
    
    def extract_images(self, file_path: str, save_dir: Optional[str] = None) -> Dict[str, str]:
        """
        提取并保存图片
        
        Args:
            file_path: PDF文件路径
            save_dir: 图片保存目录 (可选)
            
        Returns:
            图片文件名到路径的映射
        """
        result = self.parse_pdf(file_path, return_images=True)
        images = result.get('images', {})
        
        if save_dir and images:
            os.makedirs(save_dir, exist_ok=True)
            saved_paths = {}
            
            for img_name, base64_data in images.items():
                img_path = os.path.join(save_dir, img_name)
                with open(img_path, 'wb') as f:
                    f.write(base64.b64decode(base64_data))
                saved_paths[img_name] = img_path
            
            return saved_paths
        
        return images
    
    def close(self):
        """关闭会话"""
        self.session.close()

class DualVersionClient:
    """双版本MinerU客户端"""
    
    def __init__(self, 
                 simple_url: str = "http://localhost:8000",
                 full_url: str = "http://localhost:8001"):
        """
        初始化双版本客户端
        
        Args:
            simple_url: 简化版API地址
            full_url: 完整版API地址
        """
        self.simple_client = MinerUClient(simple_url, timeout=120)
        self.full_client = MinerUClient(full_url, timeout=600)
    
    def check_services(self) -> Dict[str, Dict[str, Any]]:
        """检查两个服务的状态"""
        try:
            simple_status = self.simple_client.health_check()
        except Exception as e:
            simple_status = {"error": str(e)}
        
        try:
            full_status = self.full_client.health_check()
        except Exception as e:
            full_status = {"error": str(e)}
        
        return {
            "simple": simple_status,
            "full": full_status
        }
    
    def parse_with_best_version(self, 
                              file_path: str,
                              prefer_accuracy: bool = False,
                              **kwargs) -> Dict[str, Any]:
        """
        根据需求选择最佳版本解析
        
        Args:
            file_path: PDF文件路径
            prefer_accuracy: 是否优先选择准确性 (选择完整版)
            **kwargs: 其他解析参数
        """
        if prefer_accuracy:
            return self.full_client.parse_pdf(file_path, **kwargs)
        else:
            return self.simple_client.parse_pdf(file_path, **kwargs)
    
    def compare_versions(self, file_path: str) -> Dict[str, Any]:
        """
        对比两个版本的解析结果
        
        Args:
            file_path: PDF文件路径
            
        Returns:
            对比结果
        """
        import concurrent.futures
        
        def parse_simple():
            return self.simple_client.parse_pdf(file_path)
        
        def parse_full():
            return self.full_client.parse_pdf(file_path)
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            future_simple = executor.submit(parse_simple)
            future_full = executor.submit(parse_full)
            
            try:
                simple_result = future_simple.result(timeout=180)
            except Exception as e:
                simple_result = {"error": str(e)}
            
            try:
                full_result = future_full.result(timeout=700)
            except Exception as e:
                full_result = {"error": str(e)}
        
        # 生成对比报告
        comparison = {
            "simple_version": simple_result,
            "full_version": full_result,
            "comparison": {}
        }
        
        if "error" not in simple_result and "error" not in full_result:
            simple_content = simple_result.get('md_content', '')
            full_content = full_result.get('md_content', '')
            
            comparison["comparison"] = {
                "content_length_ratio": len(full_content) / len(simple_content) if simple_content else 0,
                "simple_length": len(simple_content),
                "full_length": len(full_content),
                "formula_count_simple": simple_content.count('$'),
                "formula_count_full": full_content.count('$'),
                "processing_time_simple": simple_result.get('_client_processing_time', 0),
                "processing_time_full": full_result.get('_client_processing_time', 0)
            }
        
        return comparison
    
    def close(self):
        """关闭所有连接"""
        self.simple_client.close()
        self.full_client.close()
```

---

## 🚀 使用示例

### 基础使用

```python
# 初始化客户端
client = MinerUClient("http://localhost:8000")

# 健康检查
health = client.health_check()
print(f"服务状态: {health['status']}")

# 基础解析
result = client.parse_pdf("document.pdf")
print(f"内容: {result['md_content'][:200]}...")

# 提取Markdown
markdown = client.extract_markdown("document.pdf")
with open("output.md", "w", encoding="utf-8") as f:
    f.write(markdown)
```

### 高级使用 (完整版)

```python
# 完整版客户端
full_client = MinerUClient("http://localhost:8001")

# 高级解析 (包含公式和图片)
result = full_client.parse_pdf(
    "academic_paper.pdf",
    parse_method="auto",
    save_files=True,
    return_images=True,
    return_layout=True
)

# 检查公式识别结果
formula_count = result['md_content'].count('$')
print(f"识别到 {formula_count} 个LaTeX公式")

# 保存图片
images = full_client.extract_images("academic_paper.pdf", "extracted_images/")
print(f"提取了 {len(images)} 张图片")
```

### 双版本对比

```python
# 双版本客户端
dual_client = DualVersionClient()

# 检查服务状态
status = dual_client.check_services()
print(f"简化版: {status['simple']['status']}")
print(f"完整版: {status['full']['status']}")

# 版本对比
comparison = dual_client.compare_versions("research_paper.pdf")
comp_data = comparison['comparison']

print(f"内容增强: {comp_data['content_length_ratio']:.2f}x")
print(f"公式识别: 简化版{comp_data['formula_count_simple']} vs 完整版{comp_data['formula_count_full']}")
print(f"处理时间: 简化版{comp_data['processing_time_simple']:.1f}s vs 完整版{comp_data['processing_time_full']:.1f}s")

# 根据需求选择版本
if comp_data['formula_count_full'] > 0:
    print("推荐使用完整版 (包含公式)")
else:
    print("推荐使用简化版 (更快速)")

dual_client.close()
```

---

## ⚠️ 错误处理

### 常见状态码

| 状态码 | 含义 | 处理建议 |
|--------|------|----------|
| 200 | 成功 | 正常处理结果 |
| 400 | 请求错误 | 检查参数格式和必需参数 |
| 413 | 文件过大 | 减小文件大小或分页处理 |
| 422 | 参数错误 | 检查参数类型和值 |
| 500 | 服务器错误 | 重试或检查服务日志 |
| 503 | 服务不可用 | 等待服务恢复 |

### 错误处理示例

```python
import time
import requests

def robust_parse(client, file_path, max_retries=3):
    """带重试机制的解析"""
    for attempt in range(max_retries):
        try:
            return client.parse_pdf(file_path)
        except requests.exceptions.Timeout:
            if attempt < max_retries - 1:
                print(f"超时重试 {attempt + 1}/{max_retries}")
                time.sleep(2 ** attempt)  # 指数退避
                continue
            raise
        except requests.exceptions.ConnectionError:
            if attempt < max_retries - 1:
                print(f"连接错误重试 {attempt + 1}/{max_retries}")
                time.sleep(5)
                continue
            raise
        except Exception as e:
            if "500" in str(e) and attempt < max_retries - 1:
                print(f"服务器错误重试 {attempt + 1}/{max_retries}")
                time.sleep(5)
                continue
            raise

# 使用示例
client = MinerUClient()
try:
    result = robust_parse(client, "document.pdf")
    print("解析成功!")
except Exception as e:
    print(f"解析失败: {e}")
finally:
    client.close()
```

---

## 🔧 性能优化建议

### 1. 超时设置
```python
# 根据版本调整超时
simple_client = MinerUClient("http://localhost:8000", timeout=120)  # 2分钟
full_client = MinerUClient("http://localhost:8001", timeout=600)    # 10分钟
```

### 2. 并发处理
```python
import concurrent.futures

def batch_process(file_paths, client):
    """批量处理多个文件"""
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        futures = {executor.submit(client.parse_pdf, path): path 
                  for path in file_paths}
        
        results = {}
        for future in concurrent.futures.as_completed(futures):
            file_path = futures[future]
            try:
                result = future.result()
                results[file_path] = result
            except Exception as e:
                results[file_path] = {"error": str(e)}
        
        return results
```

### 3. 内存管理
```python
# 大文件处理时及时清理
def process_large_batch(file_paths):
    client = MinerUClient()
    try:
        for file_path in file_paths:
            result = client.parse_pdf(file_path)
            # 处理结果
            process_result(result)
            # 清理大对象
            del result
    finally:
        client.close()
```

---

## 📊 监控和日志

### 性能监控

```python
import time
import logging

class MonitoredMinerUClient(MinerUClient):
    """带监控的客户端"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.logger = logging.getLogger(self.__class__.__name__)
        self.stats = {
            "total_requests": 0,
            "successful_requests": 0,
            "failed_requests": 0,
            "total_processing_time": 0
        }
    
    def parse_pdf(self, file_path, **kwargs):
        self.stats["total_requests"] += 1
        start_time = time.time()
        file_size = os.path.getsize(file_path)
        
        try:
            result = super().parse_pdf(file_path, **kwargs)
            duration = time.time() - start_time
            self.stats["successful_requests"] += 1
            self.stats["total_processing_time"] += duration
            
            self.logger.info(f"解析成功: {file_path}, "
                           f"大小: {file_size}字节, "
                           f"耗时: {duration:.2f}秒, "
                           f"内容长度: {len(result.get('md_content', ''))}")
            return result
            
        except Exception as e:
            duration = time.time() - start_time
            self.stats["failed_requests"] += 1
            
            self.logger.error(f"解析失败: {file_path}, "
                            f"错误: {e}, "
                            f"耗时: {duration:.2f}秒")
            raise
    
    def get_stats(self):
        """获取统计信息"""
        success_rate = (self.stats["successful_requests"] / 
                       self.stats["total_requests"] * 100 
                       if self.stats["total_requests"] > 0 else 0)
        
        avg_time = (self.stats["total_processing_time"] / 
                   self.stats["successful_requests"] 
                   if self.stats["successful_requests"] > 0 else 0)
        
        return {
            **self.stats,
            "success_rate": f"{success_rate:.1f}%",
            "average_processing_time": f"{avg_time:.2f}秒"
        }
```

---

## 🎯 最佳实践

### 1. 版本选择策略
```python
def choose_optimal_version(file_path, requirements):
    """智能选择版本"""
    file_size = os.path.getsize(file_path)
    
    # 小文件优先简化版
    if file_size < 1024 * 1024:  # 1MB
        return "simple"
    
    # 需要公式识别用完整版
    if requirements.get("need_formulas", False):
        return "full"
    
    # 需要高精度表格识别用完整版
    if requirements.get("need_advanced_tables", False):
        return "full"
    
    # 默认简化版
    return "simple"
```

### 2. 错误恢复机制
```python
def smart_parse(file_path):
    """智能解析 - 自动降级"""
    dual_client = DualVersionClient()
    
    try:
        # 先尝试完整版
        return dual_client.full_client.parse_pdf(file_path)
    except Exception as e:
        print(f"完整版解析失败: {e}, 降级到简化版")
        try:
            return dual_client.simple_client.parse_pdf(file_path)
        except Exception as e2:
            print(f"简化版也失败: {e2}")
            raise
    finally:
        dual_client.close()
```

### 3. 结果缓存
```python
import hashlib
import pickle
import os

class CachedMinerUClient(MinerUClient):
    """带缓存的客户端"""
    
    def __init__(self, cache_dir="./cache", *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.cache_dir = cache_dir
        os.makedirs(cache_dir, exist_ok=True)
    
    def _get_cache_key(self, file_path, **kwargs):
        """生成缓存键"""
        with open(file_path, 'rb') as f:
            file_hash = hashlib.md5(f.read()).hexdigest()
        
        params_str = str(sorted(kwargs.items()))
        params_hash = hashlib.md5(params_str.encode()).hexdigest()
        
        return f"{file_hash}_{params_hash}.cache"
    
    def parse_pdf(self, file_path, use_cache=True, **kwargs):
        """带缓存的解析"""
        if use_cache:
            cache_key = self._get_cache_key(file_path, **kwargs)
            cache_path = os.path.join(self.cache_dir, cache_key)
            
            # 检查缓存
            if os.path.exists(cache_path):
                with open(cache_path, 'rb') as f:
                    print(f"使用缓存结果: {file_path}")
                    return pickle.load(f)
        
        # 解析并缓存
        result = super().parse_pdf(file_path, **kwargs)
        
        if use_cache:
            with open(cache_path, 'wb') as f:
                pickle.dump(result, f)
                print(f"结果已缓存: {cache_path}")
        
        return result
```

---

这份文档提供了MinerU API的完整调用指南，包括基础用法、高级功能、错误处理和性能优化。您可以根据项目需求选择合适的功能模块进行集成。