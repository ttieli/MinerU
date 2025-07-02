# MinerU API 使用指南

## 🌐 API概览

MinerU提供RESTful API服务，支持PDF文档解析和多种输出格式。

### 🔗 服务地址
- **简化版**: http://localhost:8000
- **完整版**: http://localhost:8001

### 📚 API文档
- **Swagger UI**: `/docs` (如: http://localhost:8000/docs)
- **ReDoc**: `/redoc` (如: http://localhost:8000/redoc)

## 🛡️ 核心端点

### 1. 健康检查
```http
GET /health
```

**响应示例**:
```json
{
  "status": "healthy",
  "version": "2.0",
  "timestamp": "2025-07-02T14:21:18Z"
}
```

### 2. PDF文件解析
```http
POST /file_parse
```

**请求参数**:
- `file`: PDF文件 (multipart/form-data)
- `parse_method`: 解析方法 ("auto", "ocr", "txt")
- `is_json_md_dump`: 是否输出JSON格式 ("true", "false")

**cURL示例**:
```bash
curl -X POST "http://localhost:8000/file_parse" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@document.pdf" \
  -F "parse_method=auto" \
  -F "is_json_md_dump=false"
```

**响应示例**:
```json
{
  "md_content": "# Document Title\n\nContent here...",
  "processing_time": 7.14,
  "page_count": 10,
  "features": {
    "has_tables": true,
    "has_formulas": false,
    "formula_count": 0
  }
}
```

## 🐍 Python SDK

### 基础使用
```python
import requests
import json

class MinerUClient:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
    
    def health_check(self):
        """检查服务健康状态"""
        response = requests.get(f"{self.base_url}/health")
        return response.json()
    
    def parse_pdf(self, file_path, parse_method="auto", output_json=False):
        """解析PDF文件"""
        with open(file_path, 'rb') as f:
            files = {'file': (file_path, f, 'application/pdf')}
            data = {
                'parse_method': parse_method,
                'is_json_md_dump': str(output_json).lower()
            }
            
            response = requests.post(
                f"{self.base_url}/file_parse",
                files=files,
                data=data,
                timeout=300
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"API Error: {response.status_code} - {response.text}")

# 使用示例
client = MinerUClient("http://localhost:8000")  # 简化版
# client = MinerUClient("http://localhost:8001")  # 完整版

# 健康检查
health = client.health_check()
print(f"服务状态: {health['status']}")

# 解析PDF
result = client.parse_pdf("document.pdf")
print(f"解析结果: {len(result['md_content'])} 字符")
```

### 高级功能
```python
class AdvancedMinerUClient(MinerUClient):
    def compare_versions(self, file_path):
        """对比两个版本的解析结果"""
        # 简化版解析
        simple_client = MinerUClient("http://localhost:8000")
        simple_result = simple_client.parse_pdf(file_path)
        
        # 完整版解析
        full_client = MinerUClient("http://localhost:8001")
        full_result = full_client.parse_pdf(file_path)
        
        return {
            "simplified": {
                "content_length": len(simple_result['md_content']),
                "processing_time": simple_result.get('processing_time', 0),
                "formula_count": simple_result['md_content'].count('$')
            },
            "full": {
                "content_length": len(full_result['md_content']),
                "processing_time": full_result.get('processing_time', 0),
                "formula_count": full_result['md_content'].count('$')
            }
        }
    
    def batch_process(self, file_paths):
        """批量处理PDF文件"""
        results = []
        for file_path in file_paths:
            try:
                result = self.parse_pdf(file_path)
                results.append({
                    "file": file_path,
                    "status": "success",
                    "content_length": len(result['md_content'])
                })
            except Exception as e:
                results.append({
                    "file": file_path,
                    "status": "error",
                    "error": str(e)
                })
        return results
```

## 📋 解析方法对比

### auto (推荐)
- **描述**: 自动选择最优解析方式
- **适用**: 大多数PDF文档
- **特点**: 智能文本+OCR结合

### ocr
- **描述**: 强制使用OCR识别
- **适用**: 扫描版PDF、图片PDF
- **特点**: 处理时间较长，精度高

### txt  
- **描述**: 直接提取文本
- **适用**: 纯文本PDF
- **特点**: 处理速度快

## 🎯 版本差异

### 简化版特性
```python
# 简化版API响应
{
  "md_content": "文档内容...",
  "processing_time": 7.14,
  "features": {
    "has_tables": true,
    "has_formulas": false,  # 不支持公式识别
    "formula_count": 0
  }
}
```

### 完整版增强
```python
# 完整版API响应
{
  "md_content": "文档内容...",
  "processing_time": 66.38,
  "features": {
    "has_tables": true,
    "has_formulas": true,    # 支持公式识别
    "formula_count": 76,     # LaTeX公式数量
    "vlm_analysis": {        # VLM分析结果
      "layout_quality": "high",
      "content_type": "academic"
    }
  }
}
```

## ⚡ 性能优化

### 1. 超时设置
```python
# 根据版本调整超时时间
timeout_settings = {
    "simplified": 60,    # 简化版60秒
    "full": 300         # 完整版300秒
}

response = requests.post(
    url, 
    files=files, 
    data=data, 
    timeout=timeout_settings["full"]
)
```

### 2. 并发处理
```python
import concurrent.futures
import threading

class ConcurrentMinerU:
    def __init__(self):
        self.simple_client = MinerUClient("http://localhost:8000")
        self.full_client = MinerUClient("http://localhost:8001")
    
    def parallel_process(self, file_paths):
        """并行处理多个文件"""
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            futures = []
            for file_path in file_paths:
                future = executor.submit(self.simple_client.parse_pdf, file_path)
                futures.append((file_path, future))
            
            results = []
            for file_path, future in futures:
                try:
                    result = future.result(timeout=300)
                    results.append({"file": file_path, "result": result})
                except Exception as e:
                    results.append({"file": file_path, "error": str(e)})
            
            return results
```

### 3. 错误处理
```python
class RobustMinerUClient(MinerUClient):
    def parse_pdf_with_retry(self, file_path, max_retries=3):
        """带重试机制的PDF解析"""
        for attempt in range(max_retries):
            try:
                return self.parse_pdf(file_path)
            except requests.exceptions.Timeout:
                if attempt < max_retries - 1:
                    print(f"超时重试 {attempt + 1}/{max_retries}")
                    continue
                raise
            except requests.exceptions.ConnectionError:
                if attempt < max_retries - 1:
                    print(f"连接错误重试 {attempt + 1}/{max_retries}")
                    time.sleep(2 ** attempt)  # 指数退避
                    continue
                raise
```

## 🔧 状态码说明

| 状态码 | 含义 | 处理建议 |
|--------|------|----------|
| 200 | 成功 | 正常处理结果 |
| 400 | 请求错误 | 检查参数格式 |
| 413 | 文件过大 | 减小文件大小 |
| 422 | 参数错误 | 检查必需参数 |
| 500 | 服务器错误 | 重试或检查日志 |
| 503 | 服务不可用 | 等待服务恢复 |

## 📊 监控和日志

### API调用监控
```python
import time
import logging

class MonitoredMinerUClient(MinerUClient):
    def __init__(self, base_url):
        super().__init__(base_url)
        self.logger = logging.getLogger(__name__)
    
    def parse_pdf(self, file_path, **kwargs):
        start_time = time.time()
        file_size = os.path.getsize(file_path)
        
        try:
            result = super().parse_pdf(file_path, **kwargs)
            duration = time.time() - start_time
            
            self.logger.info(f"PDF解析成功: {file_path}, "
                           f"大小: {file_size}字节, "
                           f"耗时: {duration:.2f}秒")
            return result
            
        except Exception as e:
            duration = time.time() - start_time
            self.logger.error(f"PDF解析失败: {file_path}, "
                            f"错误: {e}, "
                            f"耗时: {duration:.2f}秒")
            raise
```

---

💡 **提示**: 建议先使用简化版进行功能验证，确认需求后再使用完整版进行生产处理。