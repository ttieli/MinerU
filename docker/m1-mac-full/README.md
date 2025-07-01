# MinerU M芯片 Docker 全功能版部署方案

这是一个专为Apple Silicon（M1/M2/M3/M4）芯片优化的MinerU全功能Docker部署方案，支持所有核心功能：

## ✨ 功能特性

### 🔧 核心功能
- ✅ **完整Pipeline模式**: 支持所有传统文档解析组件
- ✅ **VLM多模态大模型**: 端到端高精度文档理解
- ✅ **双解析引擎**: Pipeline + VLM混合模式，最佳准确率
- ✅ **表格识别**: RapidTable + SlaNet Plus高精度表格解析
- ✅ **公式识别**: UniMerNet数学公式检测与识别
- ✅ **多语言OCR**: 支持中英文及多种语言OCR识别
- ✅ **布局分析**: DocLayout YOLO精确版面检测
- ✅ **阅读顺序**: LayoutReader智能阅读顺序识别
- ✅ **LLM辅助**: 支持外部LLM增强解析质量

### 🏗️ 架构优势
- ✅ **ARM64原生支持**: 为Apple Silicon芯片深度优化
- ✅ **MPS加速**: 利用Apple Metal Performance Shaders
- ✅ **多后端支持**: Pipeline、VLM-Transformers、VLM-SGLang
- ✅ **混合推理**: 自动选择最优解析策略
- ✅ **内存优化**: 智能模型切换和内存管理
- ✅ **完整API**: RESTful API + WebUI界面

## 🔧 系统要求

### 最低配置
- **硬件**: Apple Silicon M1及以上芯片
- **内存**: 16GB统一内存（推荐32GB+）
- **存储**: 20GB可用空间（模型文件约15GB）
- **系统**: macOS 12.0+ 
- **Docker**: Docker Desktop 4.0+

### 推荐配置
- **硬件**: M2 Pro/Max或M3及以上
- **内存**: 32GB+统一内存
- **存储**: 50GB+可用空间（支持大批量处理）
- **网络**: 稳定网络连接（首次下载模型）

## 🚀 快速开始

### 1. 构建全功能镜像

```bash
# 克隆或进入项目目录
cd docker/m1-mac-full

# 构建全功能镜像
docker build -t mineru-m1-full:latest .

# 或者使用预构建脚本
chmod +x build.sh
./build.sh
```

### 2. 启动服务

#### 基础启动（推荐）
```bash
# 使用docker compose启动完整服务栈
docker compose up -d

# 查看服务状态
docker compose ps
```

#### 高级启动配置
```bash
# 启动包含WebUI的完整服务
docker compose --profile webui up -d

# 启动包含监控的生产环境
docker compose --profile production up -d

# 手动指定资源限制
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### 3. 验证服务

```bash
# 健康检查
curl http://localhost:8000/health

# 查看API文档
open http://localhost:8000/docs

# 访问WebUI界面（如果启用）
open http://localhost:3000

# 检查服务日志
docker compose logs -f mineru-full
```

## 📋 配置说明

### 环境变量配置

```bash
# 模型源配置
MINERU_MODEL_SOURCE=huggingface  # huggingface/modelscope/local

# 设备配置
DEVICE_MODE=mps                   # mps/cpu
MPS_MEMORY_LIMIT=8G              # MPS显存限制

# 性能配置
MAX_WORKERS=4                     # 最大工作进程数
BATCH_SIZE=2                      # 批处理大小
MEMORY_LIMIT=8G                   # 内存限制

# 功能开关
ENABLE_VLM=true                   # 启用VLM模式
ENABLE_PIPELINE=true              # 启用Pipeline模式
ENABLE_TABLE=true                 # 启用表格识别
ENABLE_FORMULA=true               # 启用公式识别
ENABLE_LLM_AIDED=false            # LLM辅助（需要API密钥）

# LLM配置（可选）
LLM_API_KEY=your_api_key
LLM_BASE_URL=https://api.openai.com/v1
LLM_MODEL=gpt-4
```

### 解析模式配置

#### Pipeline模式（传统高精度）
```json
{
  "backend": "pipeline",
  "method": "auto",
  "enable_formula": true,
  "enable_table": true,
  "enable_llm_aided": false
}
```

#### VLM模式（端到端快速）
```json
{
  "backend": "vlm-transformers",
  "model_precision": "fp16",
  "max_new_tokens": 2048
}
```

#### 混合模式（最佳效果）
```json
{
  "backend": "auto",
  "fallback_strategy": "pipeline_first",
  "quality_threshold": 0.85
}
```

## 🔗 API使用指南

### 文档解析API

#### 基础解析
```bash
curl -X POST "http://localhost:8000/parse" \
  -F "file=@document.pdf" \
  -F "backend=auto" \
  -F "return_format=markdown"
```

#### 高级解析配置
```bash
curl -X POST "http://localhost:8000/parse" \
  -F "file=@document.pdf" \
  -F "backend=pipeline" \
  -F "method=auto" \
  -F "enable_formula=true" \
  -F "enable_table=true" \
  -F "enable_vlm_fallback=true" \
  -F "return_layout=true" \
  -F "return_content_list=true" \
  -F "return_images=true"
```

#### VLM专用解析
```bash
curl -X POST "http://localhost:8000/vlm_parse" \
  -F "file=@document.pdf" \
  -F "prompt=请详细解析这个文档的结构和内容" \
  -F "max_tokens=4096" \
  -F "temperature=0.1"
```

#### 批量解析
```bash
curl -X POST "http://localhost:8000/batch_parse" \
  -F "files=@doc1.pdf" \
  -F "files=@doc2.pdf" \
  -F "backend=auto" \
  -F "parallel_workers=2"
```

### 模型管理API

```bash
# 查看已加载模型
curl http://localhost:8000/models/status

# 切换解析后端
curl -X POST "http://localhost:8000/models/switch" \
  -H "Content-Type: application/json" \
  -d '{"backend": "vlm-transformers"}'

# 预热模型
curl -X POST "http://localhost:8000/models/warmup" \
  -H "Content-Type: application/json" \
  -d '{"models": ["pipeline", "vlm"]}'
```

## 🎨 WebUI界面

启用WebUI后，可通过浏览器访问 `http://localhost:3000` 使用图形界面：

### 功能特性
- 📄 **拖拽上传**: 支持PDF、图片、Office文档
- ⚙️ **实时配置**: 动态调整解析参数
- 📊 **进度监控**: 实时查看解析进度
- 📋 **结果预览**: 在线预览Markdown结果
- 🖼️ **图像查看**: 提取的图片和表格可视化
- 📈 **性能监控**: 实时查看资源使用情况

## 🔧 性能优化

### 内存优化策略

```yaml
# docker-compose.override.yml
services:
  mineru-full:
    environment:
      # 模型量化
      - MODEL_PRECISION=fp16
      - ENABLE_MODEL_QUANTIZATION=true
      
      # 内存管理
      - MEMORY_EFFICIENT_MODE=true
      - MODEL_OFFLOAD_CPU=true
      - CLEAR_CACHE_INTERVAL=100
      
      # 批处理优化
      - ADAPTIVE_BATCH_SIZE=true
      - MAX_CONCURRENT_REQUESTS=4
    
    deploy:
      resources:
        limits:
          memory: 16G
        reservations:
          memory: 8G
```

### MPS优化配置

```bash
# 启用MPS优化
export PYTORCH_ENABLE_MPS_FALLBACK=1
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# 设置MPS内存限制
export MPS_MEMORY_FRACTION=0.8
```

### 并发处理优化

```yaml
services:
  mineru-full:
    environment:
      - WORKER_PROCESSES=4          # 工作进程数
      - WORKER_THREADS=2            # 每进程线程数
      - QUEUE_MAX_SIZE=100          # 队列最大长度
      - REQUEST_TIMEOUT=300         # 请求超时时间
```

## 📦 部署模式

### 开发模式
```bash
# 挂载源代码进行开发
docker compose -f docker-compose.dev.yml up -d
```

### 生产模式
```bash
# 包含监控、日志收集等
docker compose --profile production up -d
```

### 集群模式
```bash
# 多实例负载均衡
docker compose -f docker-compose.cluster.yml up -d --scale mineru-full=3
```

## 🔍 监控和维护

### 日志管理
```bash
# 查看服务日志
docker compose logs -f mineru-full

# 查看特定组件日志
docker compose logs -f mineru-full | grep "VLM"
docker compose logs -f mineru-full | grep "Pipeline"

# 导出日志
docker compose logs mineru-full > mineru.log
```

### 性能监控
```bash
# 查看资源使用
docker stats mineru-full-api

# 查看GPU使用（MPS）
sudo powermetrics -n 1 -s gpu_power

# 内存使用分析
docker exec mineru-full-api python -c "
import psutil
print(f'Memory: {psutil.virtual_memory().percent}%')
print(f'CPU: {psutil.cpu_percent()}%')
"
```

### 健康检查
```bash
# 自动健康检查
curl http://localhost:8000/health/detailed

# 模型状态检查
curl http://localhost:8000/health/models

# 性能基准测试
curl -X POST "http://localhost:8000/benchmark" \
  -F "test_file=@test.pdf"
```

## 🔧 故障排除

### 常见问题

#### 1. 内存不足
```bash
# 解决方案：增加内存限制或启用交换
docker compose down
export MEMORY_LIMIT=20G
docker compose up -d
```

#### 2. 模型下载失败
```bash
# 使用国内镜像源
export MINERU_MODEL_SOURCE=modelscope
docker compose restart mineru-full

# 手动下载模型
docker exec mineru-full-api mineru-models-download -s modelscope -m all
```

#### 3. MPS不可用
```bash
# 检查MPS支持
python -c "import torch; print(torch.backends.mps.is_available())"

# 降级到CPU模式
export DEVICE_MODE=cpu
docker compose restart mineru-full
```

#### 4. API响应慢
```bash
# 启用模型预热
curl -X POST "http://localhost:8000/models/warmup"

# 调整并发参数
export MAX_WORKERS=2
export BATCH_SIZE=1
docker compose restart mineru-full
```

### 性能诊断

```bash
# 运行性能诊断
docker exec mineru-full-api python -c "
from mineru.utils.performance import system_info
print(system_info())
"

# 模型性能测试
docker exec mineru-full-api python -c "
from mineru.benchmark import run_benchmark
run_benchmark('/app/test_docs/')
"
```

## 📚 高级用法

### 自定义模型配置

```json
{
  "models": {
    "pipeline": {
      "layout_model": "doclayout_yolo",
      "ocr_model": "paddleocr_torch",
      "formula_model": "unimernet_small",
      "table_model": "rapid_table"
    },
    "vlm": {
      "model_name": "opendatalab/MinerU2.0-2505-0.9B",
      "precision": "fp16",
      "max_memory": "8GB"
    }
  }
}
```

### 插件扩展

```python
# custom_plugin.py
from mineru.plugins import BasePlugin

class CustomProcessorPlugin(BasePlugin):
    def process_document(self, doc_data):
        # 自定义处理逻辑
        return enhanced_doc_data

# 注册插件
docker exec mineru-full-api python -c "
from mineru.plugins import register_plugin
from custom_plugin import CustomProcessorPlugin
register_plugin('custom_processor', CustomProcessorPlugin)
"
```

### 批量处理脚本

```bash
#!/bin/bash
# batch_process.sh
for file in /input/*.pdf; do
    echo "Processing: $file"
    curl -X POST "http://localhost:8000/parse" \
        -F "file=@$file" \
        -F "backend=auto" \
        -o "/output/$(basename "$file" .pdf).json"
done
```

## 📋 最佳实践

### 1. 资源配置建议
- **M1/M2 基础版**: 16GB内存，4个worker进程
- **M2/M3 Pro版**: 32GB内存，6个worker进程  
- **M2/M3 Max版**: 64GB内存，8个worker进程

### 2. 模型选择策略
- **高精度需求**: Pipeline模式 + 完整模型
- **快速处理**: VLM模式 + fp16精度
- **平衡模式**: Auto模式 + 混合策略

### 3. 批量处理优化
- 使用异步API接口
- 合理设置并发数量
- 启用模型缓存机制

## 📄 许可证

本项目基于 AGPL-3.0 许可证开源。

## 🆘 技术支持

- 📧 提交Issue: [GitHub Issues](https://github.com/opendatalab/MinerU/issues)
- 💬 社区讨论: [Discussions](https://github.com/opendatalab/MinerU/discussions)
- 📖 文档中心: [MinerU Documentation](https://mineru.net/)

---

**享受高效的文档解析体验！** 🎉