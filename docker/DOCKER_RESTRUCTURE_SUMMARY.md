# Docker结构重构完成总结

## 🎯 重构目标达成

已成功将分散的Docker配置统一到 `docker/mineru/` 目录下，实现了统一的MinerU镜像架构，支持Simple和Full两个版本的并行部署。

## 📂 新的目录结构

```
docker/mineru/                    # 统一的MinerU Docker目录
├── Dockerfile                    # 统一的多阶段构建文件
├── docker-compose.yml           # 统一的容器编排配置
├── start.sh                     # 智能启动管理脚本
├── entrypoint.sh                # 容器启动脚本
├── healthcheck.sh               # 健康检查脚本
├── .env.template                # 环境变量模板
├── README.md                    # 详细使用文档
├── config/                      # 配置文件目录
│   ├── simple/                  # Simple版本配置
│   └── full/                    # Full版本配置
├── nginx/                       # Nginx负载均衡配置
│   └── nginx.conf              # 负载均衡配置文件
├── models/                      # 模型文件存储
│   ├── simple/                  # Simple版本模型
│   └── full/                    # Full版本模型
├── output/                      # 输出文件目录
│   ├── simple/                  # Simple版本输出
│   └── full/                    # Full版本输出
├── temp/                        # 临时文件目录
│   ├── simple/                  # Simple版本临时文件
│   └── full/                    # Full版本临时文件
└── logs/                        # 日志文件目录
    ├── simple/                  # Simple版本日志
    └── full/                    # Full版本日志
```

## 🚀 核心特性

### 1. 统一镜像架构
- **单一Dockerfile**: 通过构建参数支持两个版本
- **多阶段构建**: 优化镜像大小和构建效率
- **智能配置**: 根据版本自动选择依赖和模型

### 2. 并行部署支持
- **Simple版本**: 端口8000，轻量级，6个并发
- **Full版本**: 端口8001，完整功能，4个并发
- **独立资源**: 各自的存储、配置和日志

### 3. 智能管理脚本
```bash
./start.sh simple     # 启动Simple版本
./start.sh full       # 启动Full版本  
./start.sh both       # 启动两个版本
./start.sh status     # 查看状态
./start.sh logs       # 查看日志
./start.sh clean      # 清理资源
```

## 🔧 技术实现

### Dockerfile多阶段构建
```dockerfile
# 基础镜像阶段
FROM python:3.10-slim as base

# 依赖安装阶段
FROM base as dependencies
# 根据VERSION参数选择不同的requirements

# 模型下载阶段  
FROM dependencies as models
# 根据VERSION参数下载不同的模型

# 应用配置阶段
FROM models as app
# 根据VERSION参数配置不同的应用文件
```

### Docker Compose服务配置
```yaml
services:
  mineru-simple:
    build:
      args:
        VERSION: simple
    ports:
      - "8000:8000"
    
  mineru-full:
    build:
      args:
        VERSION: full
    ports:
      - "8001:8000"
```

## 📊 版本对比

| 特性 | Simple版本 | Full版本 |
|------|------------|----------|
| **镜像名称** | `mineru:simple-latest` | `mineru:full-latest` |
| **容器名称** | `mineru-simple` | `mineru-full` |
| **外部端口** | 8000 | 8001 |
| **内部端口** | 8000 | 8000 |
| **内存限制** | 4GB | 16GB |
| **CPU限制** | 2.0核 | 8.0核 |
| **并发能力** | 6个请求 | 4个请求 |
| **功能支持** | 基础解析+表格 | 全功能+VLM+公式 |
| **适用场景** | 日常使用 | 专业分析 |

## 🎛 配置管理

### 环境变量配置
```bash
# 复制配置模板
cp .env.template .env

# 关键配置项
DEVICE_MODE=cpu              # 设备模式
SIMPLE_MAX_WORKERS=6         # Simple版本并发数
FULL_MAX_WORKERS=4           # Full版本并发数
ENABLE_VLM=true             # 启用VLM (Full版本)
MEMORY_EFFICIENT_MODE=true   # 内存优化模式
```

### 资源路径配置
```bash
# 模型路径
SIMPLE_MODELS_PATH=./models/simple
FULL_MODELS_PATH=./models/full

# 输出路径自动分离
./output/simple/    # Simple版本输出
./output/full/      # Full版本输出
```

## 🔍 监控和管理

### 健康检查
```bash
# 自动健康检查
curl http://localhost:8000/health  # Simple版本
curl http://localhost:8001/health  # Full版本

# 异步状态监控
curl http://localhost:8000/status  # Simple版本状态
curl http://localhost:8001/status  # Full版本状态
```

### 日志管理
```bash
# 查看特定版本日志
./start.sh logs simple
./start.sh logs full

# 实时日志追踪
docker-compose logs -f mineru-simple
docker-compose logs -f mineru-full
```

## 🚦 负载均衡 (可选)

### Nginx智能路由
```nginx
# 简化版API
location /api/simple/ {
    proxy_pass http://mineru-simple:8000/;
}

# 完整版API  
location /api/full/ {
    proxy_pass http://mineru-full:8000/;
}

# 智能负载均衡
location /api/ {
    proxy_pass http://mineru-balanced/;  # 3:1权重分配
}
```

### 启用负载均衡
```bash
# 启动生产环境配置
docker-compose --profile production up -d

# 访问负载均衡API
curl http://localhost/api/file_parse -F "file=@test.pdf"
```

## 📈 性能优化

### 资源隔离
- **独立容器**: 避免资源竞争
- **独立存储**: 避免文件冲突  
- **独立网络**: 清晰的服务边界

### 内存优化
- **分层构建**: 共享基础镜像层
- **按需加载**: 根据版本加载不同模型
- **缓存管理**: 智能清理机制

### 并发优化
- **异步处理**: 两个版本都支持异步并发
- **线程池**: 根据硬件自动调整
- **负载分配**: 智能路由到合适版本

## 🔄 迁移指南

### 从旧结构迁移

1. **备份现有配置**
   ```bash
   # 备份旧的docker配置
   cp -r docker/m1-mac docker/m1-mac.backup
   cp -r docker/m1-mac-full docker/m1-mac-full.backup
   ```

2. **使用新结构**
   ```bash
   # 切换到新目录
   cd docker/mineru
   
   # 配置环境变量
   cp .env.template .env
   vim .env
   
   # 启动服务
   ./start.sh both
   ```

3. **验证功能**
   ```bash
   # 测试两个版本
   curl http://localhost:8000/health
   curl http://localhost:8001/health
   
   # 运行性能测试
   python ../test_async_performance.py
   ```

### API兼容性

新结构完全保持API兼容性：

- **Simple版本**: `http://localhost:8000` (与原m1-mac一致)
- **Full版本**: `http://localhost:8001` (与原m1-mac-full一致)
- **请求格式**: 完全不变
- **响应格式**: 完全不变

## 🎯 使用示例

### 基本使用

```bash
# 1. 启动服务
./start.sh both

# 2. 测试Simple版本
curl -X POST http://localhost:8000/file_parse \
  -F "file=@document.pdf" \
  -F "parse_method=auto"

# 3. 测试Full版本  
curl -X POST http://localhost:8001/file_parse \
  -F "file=@document.pdf" \
  -F "parse_method=auto"

# 4. 查看状态
./start.sh status
```

### 生产环境部署

```bash
# 1. 配置生产环境变量
vim .env
# 设置合适的资源限制和安全配置

# 2. 启用HTTPS和负载均衡
docker-compose --profile production up -d

# 3. 配置SSL证书
cp cert.pem nginx/ssl/
cp key.pem nginx/ssl/

# 4. 访问负载均衡API
curl https://your-domain.com/api/file_parse \
  -F "file=@document.pdf"
```

## ✅ 重构成果

### 🎯 用户体验提升
- **统一入口**: 一个目录管理所有Docker配置
- **智能脚本**: 简化的管理命令
- **清晰文档**: 详细的使用说明

### 🔧 运维效率提升  
- **统一构建**: 单一Dockerfile支持多版本
- **资源隔离**: 避免版本间冲突
- **监控完善**: 全面的健康检查和状态监控

### 🚀 扩展性提升
- **模块化设计**: 易于添加新版本
- **配置灵活**: 环境变量驱动的配置
- **负载均衡**: 支持生产环境扩展

---

**🎉 Docker结构重构完成！现在您可以使用统一的 `docker/mineru/` 目录来管理MinerU的所有Docker部署需求。**