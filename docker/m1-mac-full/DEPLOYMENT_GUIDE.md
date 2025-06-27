# MinerU M芯片 Docker 全功能版部署指南

## 📖 概述

本指南提供了一个专为Apple Silicon（M1/M2/M3/M4）芯片优化的MinerU完整功能Docker部署方案。与现有的轻量级版本相比，此版本支持MinerU的所有核心功能。

### 🆚 版本对比

| 功能特性 | 轻量级版本 | 全功能版本 |
|---------|-----------|-----------|
| Pipeline模式 | ✅ 基础支持 | ✅ 完整支持 |
| VLM多模态大模型 | ❌ | ✅ |
| 表格识别 | ❌ | ✅ |
| 公式识别 | ✅ 基础 | ✅ 完整 |
| 阅读顺序检测 | ❌ | ✅ |
| LLM辅助增强 | ❌ | ✅ |
| 多后端支持 | ❌ | ✅ |
| WebUI界面 | ❌ | ✅ |
| 监控系统 | ❌ | ✅ |
| 内存占用 | ~2GB | ~8-16GB |
| 磁盘占用 | ~5GB | ~15-20GB |

## 🚀 快速开始

### 1. 环境准备

```bash
# 检查系统要求
system_profiler SPHardwareDataType | grep "Memory"
uname -m  # 应显示 arm64

# 确保Docker运行
docker --version
docker-compose --version
```

### 2. 下载部署包

```bash
# 进入项目目录
cd MinerU/docker/m1-mac-full

# 赋予执行权限
chmod +x build.sh entrypoint.sh download_models_full.py
```

### 3. 一键部署

```bash
# 完整部署（推荐）
./build.sh

# 带WebUI界面
./build.sh -w

# 带监控系统
./build.sh -M

# 开发模式
./build.sh -d

# 使用ModelScope源（国内用户）
./build.sh --source modelscope
```

### 4. 验证部署

```bash
# 检查服务状态
curl http://localhost:8000/health

# 查看详细状态
curl http://localhost:8080/health/detailed

# 测试文档解析
curl -X POST "http://localhost:8000/parse" \
  -F "file=@test.pdf" \
  -F "backend=auto"
```

## 📋 详细配置

### 系统要求

#### 最低要求
- **CPU**: Apple Silicon M1或更高
- **内存**: 16GB统一内存
- **存储**: 20GB可用空间
- **系统**: macOS 12.0+
- **Docker**: Docker Desktop 4.0+

#### 推荐配置
- **CPU**: M2 Pro/Max或M3/M4
- **内存**: 32GB+统一内存
- **存储**: 50GB+可用空间

### 环境变量配置

```bash
# 核心配置
export DEVICE_MODE=mps                    # 设备模式: mps/cpu
export ENABLE_VLM=true                    # 启用VLM模式
export ENABLE_PIPELINE=true               # 启用Pipeline模式
export ENABLE_TABLE=true                  # 启用表格识别
export ENABLE_FORMULA=true                # 启用公式识别

# 性能调优
export MAX_WORKERS=4                      # 工作进程数
export BATCH_SIZE=2                       # 批处理大小
export MEMORY_LIMIT=16G                   # 内存限制
export MPS_MEMORY_FRACTION=0.8            # MPS内存占用比例

# 模型源
export MINERU_MODEL_SOURCE=huggingface    # huggingface/modelscope
```

## 🔧 服务管理

### 启动/停止服务

```bash
# 启动所有服务
docker-compose up -d

# 启动指定服务
docker-compose up -d mineru-full

# 停止服务
docker-compose down

# 重启服务
docker-compose restart mineru-full
```

### 查看日志

```bash
# 查看实时日志
docker-compose logs -f mineru-full

# 查看特定组件日志
docker-compose logs -f mineru-full | grep "VLM"
docker-compose logs -f mineru-full | grep "Pipeline"

# 导出日志
docker-compose logs mineru-full > mineru.log
```

### 资源监控

```bash
# 查看容器资源使用
docker stats mineru-full-api

# 查看GPU使用（MPS）
sudo powermetrics -n 1 -s gpu_power

# 内存使用详情
docker exec mineru-full-api python -c "
import psutil
mem = psutil.virtual_memory()
print(f'内存使用: {mem.percent}%')
print(f'可用内存: {mem.available//1024//1024}MB')
"
```

## 🎯 API使用指南

### 基础解析API

```bash
# 自动模式解析
curl -X POST "http://localhost:8000/parse" \
  -F "file=@document.pdf" \
  -F "backend=auto"

# Pipeline模式解析
curl -X POST "http://localhost:8000/parse" \
  -F "file=@document.pdf" \
  -F "backend=pipeline" \
  -F "enable_table=true" \
  -F "enable_formula=true"

# VLM模式解析
curl -X POST "http://localhost:8000/parse" \
  -F "file=@document.pdf" \
  -F "backend=vlm-transformers" \
  -F "max_tokens=2048"
```

### 高级功能API

```bash
# 批量解析
curl -X POST "http://localhost:8000/batch_parse" \
  -F "files=@doc1.pdf" \
  -F "files=@doc2.pdf" \
  -F "backend=auto" \
  -F "parallel_workers=2"

# 模型管理
curl -X POST "http://localhost:8000/models/switch" \
  -H "Content-Type: application/json" \
  -d '{"backend": "vlm-transformers"}'

# 预热模型
curl -X POST "http://localhost:8000/models/warmup"
```

### WebUI界面使用

启用WebUI后访问 `http://localhost:3000`：

1. **文档上传**: 拖拽或点击上传PDF/图片/Office文档
2. **参数配置**: 实时调整解析参数
3. **结果预览**: 在线查看Markdown结果
4. **进度监控**: 实时查看解析进度
5. **性能监控**: 查看系统资源使用情况

## 🔧 性能优化

### 内存优化

```yaml
# docker-compose.override.yml
services:
  mineru-full:
    environment:
      # 启用内存优化
      - MEMORY_EFFICIENT_MODE=true
      - MODEL_OFFLOAD_CPU=true
      - CLEAR_CACHE_INTERVAL=100
      
      # 模型量化
      - MODEL_PRECISION=fp16
      - ENABLE_MODEL_QUANTIZATION=true
    
    deploy:
      resources:
        limits:
          memory: 20G  # 根据实际内存调整
```

### MPS优化

```bash
# MPS优化设置
export PYTORCH_ENABLE_MPS_FALLBACK=1
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
export MPS_MEMORY_FRACTION=0.8

# 重启服务应用设置
docker-compose restart mineru-full
```

### 并发优化

```bash
# 调整工作进程数（根据CPU核心数）
export MAX_WORKERS=6          # M2 Pro: 6, M2 Max: 8
export WORKER_PROCESSES=6
export WORKER_THREADS=2

# 批处理优化
export BATCH_SIZE=4           # 内存充足时可增大
export ADAPTIVE_BATCH_SIZE=true
```

## 🔍 故障排除

### 常见问题

#### 1. 内存不足错误

**现象**: 容器被Kill或OOM错误

**解决方案**:
```bash
# 增加内存限制
export MEMORY_LIMIT=20G
docker-compose restart mineru-full

# 启用内存优化
export MEMORY_EFFICIENT_MODE=true
export MODEL_OFFLOAD_CPU=true
```

#### 2. 模型下载失败

**现象**: 模型下载超时或失败

**解决方案**:
```bash
# 使用国内镜像源
export MINERU_MODEL_SOURCE=modelscope
docker-compose restart mineru-full

# 手动下载模型
docker exec mineru-full-api python download_models_full.py \
  --mode all --source modelscope --cleanup
```

#### 3. MPS不可用

**现象**: MPS相关错误

**解决方案**:
```bash
# 检查MPS支持
python -c "import torch; print(torch.backends.mps.is_available())"

# 降级到CPU模式
export DEVICE_MODE=cpu
docker-compose restart mineru-full
```

#### 4. API响应慢

**现象**: 请求超时或响应慢

**解决方案**:
```bash
# 预热模型
curl -X POST "http://localhost:8000/models/warmup"

# 调整并发设置
export MAX_CONCURRENT_REQUESTS=2
export BATCH_SIZE=1
```

### 诊断工具

```bash
# 运行系统诊断
docker exec mineru-full-api python -c "
import torch
import psutil
print(f'PyTorch版本: {torch.__version__}')
print(f'MPS可用: {torch.backends.mps.is_available()}')
print(f'内存使用: {psutil.virtual_memory().percent}%')
"

# 检查模型状态
docker exec mineru-full-api python download_models_full.py --verify

# 性能基准测试
curl -X POST "http://localhost:8000/benchmark" \
  -F "test_file=@test.pdf"
```

## 📊 监控和维护

### 启用监控

```bash
# 启动完整监控栈
./build.sh -M

# 访问监控面板
open http://localhost:3001  # Grafana (admin/admin123)
open http://localhost:9090  # Prometheus
```

### 日志管理

```bash
# 配置日志轮转
docker-compose exec mineru-full logrotate -f /etc/logrotate.d/mineru

# 压缩历史日志
docker-compose exec mineru-full gzip /app/logs/*.log.1

# 清理临时文件
docker-compose exec mineru-full find /app/temp -type f -mtime +1 -delete
```

### 健康检查

```bash
# 自动健康检查
curl http://localhost:8080/health/detailed

# 模型状态检查
curl http://localhost:8000/models/status

# 系统资源检查
curl http://localhost:8080/system/stats
```

## 🔧 高级配置

### 自定义模型

```json
{
  "models": {
    "pipeline": {
      "layout_model": "custom_layout_model",
      "ocr_model": "custom_ocr_model"
    },
    "vlm": {
      "model_name": "custom_vlm_model",
      "precision": "fp16"
    }
  }
}
```

### 插件扩展

```python
# custom_plugin.py
from mineru.plugins import BasePlugin

class CustomPlugin(BasePlugin):
    def process_document(self, doc_data):
        # 自定义处理逻辑
        return enhanced_doc_data

# 注册插件
docker exec mineru-full-api python -c "
from mineru.plugins import register_plugin
from custom_plugin import CustomPlugin
register_plugin('custom', CustomPlugin)
"
```

### 集群部署

```bash
# 多实例负载均衡
docker-compose up -d --scale mineru-full=3

# 使用外部负载均衡器
# nginx.conf配置示例见 ./nginx/nginx.conf
```

## 📚 最佳实践

### 1. 资源配置建议

| 硬件配置 | 内存限制 | 工作进程 | 批处理大小 | 适用场景 |
|---------|---------|---------|-----------|---------|
| M1 8GB | 6G | 2 | 1 | 轻量使用 |
| M1 16GB | 12G | 4 | 2 | 常规使用 |
| M2 Pro 32GB | 24G | 6 | 4 | 高负载 |
| M2 Max 64GB | 48G | 8 | 8 | 批量处理 |

### 2. 模型选择策略

- **高精度需求**: Pipeline模式 + 完整模型
- **快速处理**: VLM模式 + fp16精度
- **平衡模式**: Auto模式 + 混合策略
- **资源受限**: Pipeline模式 + 核心模型

### 3. 生产部署建议

- 启用监控和日志收集
- 配置健康检查和自动重启
- 使用持久化存储卷
- 设置合理的资源限制
- 定期备份重要数据

## 🆘 技术支持

- **GitHub Issues**: [提交问题](https://github.com/opendatalab/MinerU/issues)
- **文档中心**: [MinerU Documentation](https://mineru.net/)
- **社区讨论**: [Discussions](https://github.com/opendatalab/MinerU/discussions)

## 📄 许可证

本项目基于 AGPL-3.0 许可证开源。

---

**🎉 享受高效的文档解析体验！**