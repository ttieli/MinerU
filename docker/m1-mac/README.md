# MinerU M1 Mac Docker 部署方案

这是一个专为M1芯片Mac优化的MinerU Docker部署方案，具有以下特点：

- ✅ **M1芯片原生支持**: 基于ARM64架构优化
- ✅ **低内存占用**: 限制内存使用4GB，推荐配置1-2GB
- ✅ **CPU模式运行**: 无需GPU，适合轻量级部署
- ✅ **核心模型**: 只下载必需的模型以节省空间
- ✅ **API服务**: 提供完整的RESTful API接口

## 系统要求

- macOS 12.0+ (Apple Silicon M1/M2芯片)
- Docker Desktop 4.0+
- 可用内存: 至少4GB
- 可用存储: 至少10GB

## 快速开始

### 1. 构建镜像

```bash
cd docker/m1-mac
docker build -t mineru-m1:latest .
```

### 2. 启动服务

```bash
# 基础启动
docker-compose up -d

# 或者直接运行容器
docker run -d \
  --name mineru-m1-api \
  -p 8000:8000 \
  -v $(pwd)/output:/app/output \
  mineru-m1:latest
```

### 3. 验证运行

```bash
# 检查健康状态
curl http://localhost:8000/health

# 查看API文档
open http://localhost:8000/docs
```

## API 使用示例

### 解析PDF文件

```bash
# 上传文件解析
curl -X POST "http://localhost:8000/file_parse" \
  -F "file=@your_document.pdf" \
  -F "parse_method=auto" \
  -F "return_content_list=true"

# 解析本地文件
curl -X POST "http://localhost:8000/file_parse" \
  -F "file_path=/path/to/document.pdf" \
  -F "parse_method=ocr" \
  -F "is_json_md_dump=true"
```

### 解析Office文档

```bash
curl -X POST "http://localhost:8000/file_parse" \
  -F "file=@document.docx" \
  -F "parse_method=auto"
```

### 解析图像

```bash
curl -X POST "http://localhost:8000/file_parse" \
  -F "file=@image.png" \
  -F "parse_method=ocr" \
  -F "return_images=true"
```

## 配置参数

### 环境变量

- `MINERU_MODEL_SOURCE`: 模型来源 (huggingface/modelscope/local)
- `TORCH_NUM_THREADS`: CPU线程数限制 (默认4)
- `OMP_NUM_THREADS`: OpenMP线程数限制 (默认4)

### 解析参数

- `parse_method`: 解析方法
  - `auto`: 自动选择 (推荐)
  - `ocr`: 强制OCR模式
  - `txt`: 文本提取模式
- `return_layout`: 返回布局信息
- `return_info`: 返回文档信息
- `return_content_list`: 返回内容列表
- `return_images`: 返回提取的图像

## 性能优化

### 内存优化
- 容器内存限制: 4GB
- 批处理大小: 1
- 工作进程数: 2

### CPU优化
- 线程池限制: 4个线程
- 禁用表格识别以节省资源
- 禁用LLM辅助功能

### 存储优化
- 只下载核心模型
- 使用持久化卷存储模型
- 自动清理临时文件

## 生产部署

### 使用Nginx反向代理

```bash
# 启动包含Nginx的完整服务
docker-compose --profile production up -d
```

### 扩展配置

```yaml
# docker-compose.override.yml
version: '3.8'
services:
  mineru-m1:
    deploy:
      resources:
        limits:
          memory: 6G  # 增加内存限制
          cpus: '4.0'  # 增加CPU限制
    environment:
      - TORCH_NUM_THREADS=8  # 增加线程数
```

## 故障排除

### 常见问题

1. **内存不足**
   ```bash
   # 增加内存限制
   docker-compose up -d --scale mineru-m1=1 --memory=6g
   ```

2. **模型下载失败**
   ```bash
   # 使用国内镜像源
   docker-compose up -d -e MINERU_MODEL_SOURCE=modelscope
   ```

3. **容器启动失败**
   ```bash
   # 查看日志
   docker-compose logs mineru-m1
   
   # 重新构建
   docker-compose build --no-cache
   ```

### 监控和日志

```bash
# 查看容器状态
docker-compose ps

# 查看实时日志
docker-compose logs -f mineru-m1

# 查看资源使用
docker stats mineru-m1-api
```

## 开发调试

### 本地开发模式

```bash
# 挂载源代码
docker run -it --rm \
  -v $(pwd):/app \
  -p 8000:8000 \
  mineru-m1:latest \
  bash
```

### 模型管理

```bash
# 查看已下载的模型
docker exec mineru-m1-api ls -la /opt/models

# 手动下载模型
docker exec mineru-m1-api python download_models_light.py
```

## 许可证

本项目遵循 Apache 2.0 许可证。

## 支持

如有问题请提交Issue或联系技术支持。