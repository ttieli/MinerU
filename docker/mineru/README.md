# MinerU 统一Docker部署

## 🎯 概述

MinerU统一Docker部署方案，支持Simple和Full两个版本的并行运行，提供完整的PDF解析服务。

### 版本对比

| 特性 | Simple版本 | Full版本 |
|------|------------|----------|
| **端口** | 8000 | 8001 |
| **内存需求** | 4GB | 16GB |
| **处理速度** | 快 (~7秒) | 慢 (~60秒) |
| **PDF解析** | ✅ | ✅ |
| **OCR识别** | ✅ | ✅ 增强 |
| **表格识别** | ✅ 基础 | ✅ 高级 |
| **公式识别** | ❌ | ✅ LaTeX |
| **多模态VLM** | ❌ | ✅ |
| **并发能力** | 6个请求 | 4个请求 |

## 🚀 快速启动

### 1. 准备环境

```bash
# 克隆仓库
git clone https://github.com/your-repo/MinerU.git
cd MinerU/docker/mineru

# 复制环境变量模板
cp .env.template .env

# 根据需要编辑配置
vim .env
```

### 2. 启动服务

```bash
# 启动两个版本
./start.sh both

# 或者只启动单个版本
./start.sh simple  # 只启动Simple版本
./start.sh full    # 只启动Full版本
```

### 3. 验证服务

```bash
# 检查服务状态
./start.sh status

# 测试Simple版本
curl http://localhost:8000/health

# 测试Full版本
curl http://localhost:8001/health

# 查看异步状态
curl http://localhost:8000/status  # Simple版本
curl http://localhost:8001/status  # Full版本
```

## 📋 管理命令

### 启动命令

```bash
./start.sh simple     # 启动Simple版本 (8000端口)
./start.sh full       # 启动Full版本 (8001端口)
./start.sh both       # 启动两个版本 (默认)
```

### 管理命令

```bash
./start.sh stop       # 停止所有服务
./start.sh restart    # 重启所有服务
./start.sh status     # 查看状态
./start.sh logs       # 查看所有日志
./start.sh logs simple # 查看Simple版本日志
./start.sh logs full   # 查看Full版本日志
./start.sh clean      # 清理容器和镜像
```

## 🔧 配置说明

### 环境变量

关键环境变量在 `.env` 文件中配置：

```bash
# 设备配置
DEVICE_MODE=cpu          # cpu/mps/cuda
MPS_MEMORY_LIMIT=8G      # M1/M2 Mac内存限制

# 性能配置
SIMPLE_MAX_WORKERS=6     # Simple版本并发数
FULL_MAX_WORKERS=4       # Full版本并发数

# 功能开关
ENABLE_VLM=true          # 启用VLM（仅Full版本）
ENABLE_TABLE=true        # 启用表格识别
ENABLE_FORMULA=true      # 启用公式识别（仅Full版本）

# 内存优化
MEMORY_EFFICIENT_MODE=true    # 内存高效模式
MODEL_OFFLOAD_CPU=true        # 模型CPU卸载
```

### 资源限制

```yaml
# Simple版本资源限制
resources:
  limits:
    memory: 4G
    cpus: '2.0'

# Full版本资源限制
resources:
  limits:
    memory: 16G
    cpus: '8.0'
```

## 📊 API使用

### 统一API接口

两个版本的API接口完全一致，只是端口不同：

```bash
# Simple版本 (推荐日常使用)
curl -X POST http://localhost:8000/file_parse \
  -F "file=@document.pdf" \
  -F "parse_method=auto"

# Full版本 (推荐专业分析)
curl -X POST http://localhost:8001/file_parse \
  -F "file=@document.pdf" \
  -F "parse_method=auto"
```

### 状态监控

```bash
# 健康检查
GET /health

# 异步状态
GET /status

# 返回示例
{
  "thread_pool_size": 6,
  "active_threads": 3,
  "queue_size": 0,
  "cpu_count": 8,
  "model_loaded": true,
  "version": "simple"
}
```

## 🔍 监控和日志

### 实时监控

```bash
# 查看容器状态
docker ps

# 查看资源使用
docker stats

# 查看服务日志
./start.sh logs

# 查看特定服务日志
./start.sh logs simple
./start.sh logs full
```

### 健康检查

```bash
# 检查服务健康状态
./start.sh status

# 或直接访问健康检查端点
curl http://localhost:8000/health
curl http://localhost:8001/health
```

## 🔄 负载均衡 (可选)

### 启用Nginx负载均衡

```bash
# 使用production profile启动
docker-compose --profile production up -d

# 访问负载均衡API
curl http://localhost/api/file_parse \
  -F "file=@document.pdf"

# 指定版本
curl http://localhost/api/simple/file_parse \  # 强制使用Simple版本
  -F "file=@document.pdf"

curl http://localhost/api/full/file_parse \    # 强制使用Full版本
  -F "file=@document.pdf"
```

## 🛠 故障排除

### 常见问题

1. **容器启动失败**
   ```bash
   # 检查日志
   ./start.sh logs
   
   # 检查资源使用
   docker system df
   
   # 清理资源
   ./start.sh clean
   ```

2. **内存不足**
   ```bash
   # 调整内存限制
   vim .env
   # 修改 SIMPLE_MEMORY_LIMIT 或 FULL_MEMORY_LIMIT
   
   # 重启服务
   ./start.sh restart
   ```

3. **模型下载失败**
   ```bash
   # 检查网络连接
   docker exec mineru-simple ping -c 3 8.8.8.8
   
   # 手动下载模型
   docker exec mineru-simple python download_models.py
   ```

4. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tulpn | grep :8000
   netstat -tulpn | grep :8001
   
   # 修改端口配置
   vim .env
   # 修改 SIMPLE_API_PORT 或 FULL_API_PORT
   ```

### 性能调优

1. **M1/M2 Mac优化**
   ```bash
   # 启用MPS加速
   DEVICE_MODE=mps
   MPS_MEMORY_LIMIT=8G
   PYTORCH_ENABLE_MPS_FALLBACK=1
   ```

2. **内存优化**
   ```bash
   # 启用内存高效模式
   MEMORY_EFFICIENT_MODE=true
   MODEL_OFFLOAD_CPU=true
   CLEAR_CACHE_INTERVAL=100
   ```

3. **并发调优**
   ```bash
   # 根据硬件调整并发数
   SIMPLE_MAX_WORKERS=6    # CPU核心数 × 1.5
   FULL_MAX_WORKERS=4      # CPU核心数 ÷ 2
   ```

## 📈 性能测试

### 并发测试

```bash
# 运行性能测试脚本
python ../test_async_performance.py

# 使用Apache Bench测试
ab -n 10 -c 3 -p test.pdf -T multipart/form-data \
  http://localhost:8000/file_parse
```

### 预期性能

| 版本 | 并发数 | 平均响应时间 | 吞吐量 |
|------|--------|--------------|--------|
| Simple | 6个请求 | ~7秒 | 6 PDF/批次 |
| Full | 4个请求 | ~60秒 | 4 PDF/批次 |

## 🔒 安全配置

### 生产环境安全

1. **启用HTTPS**
   ```bash
   # 配置SSL证书
   mkdir -p nginx/ssl
   cp your-cert.pem nginx/ssl/cert.pem
   cp your-key.pem nginx/ssl/key.pem
   
   # 启用production profile
   docker-compose --profile production up -d
   ```

2. **访问控制**
   ```bash
   # 限制访问IP
   # 在nginx.conf中配置allow/deny规则
   ```

3. **资源限制**
   ```bash
   # 配置合理的资源限制
   # 防止资源滥用
   ```

## 📚 相关文档

- [API文档](../../API_DOCUMENTATION.md)
- [异步升级指南](../../API_ASYNC_UPGRADE.md)
- [Docker异步升级总结](../ASYNC_UPGRADE_SUMMARY.md)
- [快速启动指南](../../QUICK_START.md)

## 🤝 支持

如遇问题请查看：
1. 项目README文档
2. 故障排除指南
3. GitHub Issues
4. 社区讨论