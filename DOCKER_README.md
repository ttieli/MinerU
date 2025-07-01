# MinerU Docker 部署指南

## 📦 支持的平台和版本

### 🍎 Apple Silicon (推荐)

- **简化版**: `docker/m1-mac/` - 适合日常使用，内存占用低
- **完整版**: `docker/m1-mac-full/` - 专业级功能，支持所有特性

### 🖥️ x86_64 平台

- **通用版**: `docker/global/` - 适用于大多数Linux和x86_64系统
- **中国版**: `docker/china/` - 针对中国用户优化的镜像源

## 🚀 快速开始

### 一键启动（推荐）

```bash
# 进入项目根目录
cd MinerU

# 运行一键启动脚本
./start_mineru_docker.sh
```

脚本会自动：
- ✅ 检测系统架构和资源
- ✅ 提供交互式版本选择
- ✅ 自动配置环境变量
- ✅ 启动和监控服务
- ✅ 提供访问地址和使用指导

### 手动部署

#### Apple Silicon M芯片

**简化版（推荐入门用户）**:
```bash
cd docker/m1-mac
docker compose up -d
```

**完整版（推荐专业用户）**:
```bash
cd docker/m1-mac-full
docker compose up -d
```

#### 通用x86_64

```bash
cd docker/global
docker compose up -d
```

## 🔧 版本对比

| 特性 | 简化版 | 完整版 |
|------|--------|--------|
| **目标用户** | 日常用户 | 专业用户 |
| **内存需求** | 4GB | 16GB+ |
| **存储需求** | 10GB | 20GB+ |
| **PDF解析** | ✅ 基础 | ✅ 高精度 |
| **OCR识别** | ✅ | ✅ |
| **表格识别** | ❌ | ✅ |
| **公式识别** | ❌ | ✅ |
| **VLM多模态** | ❌ | ✅ |
| **WebUI界面** | ❌ | ✅ |
| **监控功能** | ❌ | ✅ |

## 📋 系统要求

### Apple Silicon版本

**最低要求**:
- macOS 12.0+
- Apple Silicon (M1/M2/M3/M4)
- 8GB 统一内存
- 10GB 可用存储
- Docker Desktop 4.0+

**推荐配置**:
- macOS 13.0+
- M2 Pro/Max 或更新
- 32GB+ 统一内存
- 50GB+ 可用存储

### x86_64版本

**最低要求**:
- Linux/Windows/macOS x86_64
- 8GB RAM
- 10GB 可用存储
- Docker 20.10+

## 🔗 服务访问

启动成功后，可通过以下地址访问：

- **API服务**: http://localhost:8000
- **API文档**: http://localhost:8000/docs
- **健康检查**: http://localhost:8000/health
- **WebUI界面**: http://localhost:3000 (仅完整版)

## 📊 常用操作

### 查看服务状态
```bash
cd docker/[版本目录]
docker compose ps
```

### 查看实时日志
```bash
cd docker/[版本目录]
docker compose logs -f
```

### 停止服务
```bash
cd docker/[版本目录]
docker compose down
```

### 重启服务
```bash
cd docker/[版本目录]
docker compose restart
```

### 更新镜像
```bash
cd docker/[版本目录]
docker compose pull
docker compose up -d
```

## 🔧 环境配置

### 模型源设置

**国际用户（默认）**:
```bash
export MINERU_MODEL_SOURCE=huggingface
```

**中国用户**:
```bash
export MINERU_MODEL_SOURCE=modelscope
```

### 性能调优

**内存限制**:
```yaml
# docker-compose.override.yml
services:
  mineru-[版本]:
    deploy:
      resources:
        limits:
          memory: 8G
```

**CPU限制**:
```yaml
services:
  mineru-[版本]:
    deploy:
      resources:
        limits:
          cpus: '4.0'
```

## 🐛 故障排除

### 常见问题

**1. 端口被占用**
```bash
# 检查端口占用
lsof -i :8000

# 修改端口
echo "API_PORT=8080" >> docker/[版本]/.env
```

**2. 内存不足**
```bash
# 查看内存使用
docker stats

# 降低内存限制
export MEMORY_LIMIT=4G
```

**3. 模型下载失败**
```bash
# 切换模型源
export MINERU_MODEL_SOURCE=modelscope

# 手动下载模型
docker exec [容器名] python download_models.py
```

**4. 服务无法启动**
```bash
# 查看详细日志
docker compose logs

# 重新构建镜像
docker compose build --no-cache
```

### 性能监控

**查看资源使用**:
```bash
# 容器资源使用
docker stats

# 系统资源使用
htop
```

**Apple Silicon专用**:
```bash
# GPU/MPS使用情况
sudo powermetrics -n 1 -s gpu_power
```

## 📚 进阶用法

### 自定义配置

创建 `docker-compose.override.yml`:
```yaml
version: '3.8'
services:
  mineru-full:
    environment:
      - CUSTOM_CONFIG=value
    volumes:
      - ./custom_models:/opt/models
```

### 集群部署

```bash
# 多实例负载均衡
docker compose -f docker-compose.yml -f docker-compose.cluster.yml up -d --scale mineru-full=3
```

### 监控配置

```bash
# 启用监控服务（仅完整版）
docker compose --profile monitoring up -d
```

访问监控面板：
- Grafana: http://localhost:3001
- Prometheus: http://localhost:9090

## 🔒 安全建议

1. **生产环境**：使用Nginx反向代理
2. **访问控制**：配置防火墙规则
3. **数据安全**：定期备份重要数据
4. **更新维护**：定期更新镜像和依赖

## 📝 许可证

本项目遵循 AGPL-3.0 许可证。

## 🆘 获取帮助

- 📖 [完整文档](https://mineru.net/)
- 🐛 [问题反馈](https://github.com/opendatalab/MinerU/issues)
- 💬 [社区讨论](https://github.com/opendatalab/MinerU/discussions)

---

**快速开始**: `./start_mineru_docker.sh` 🚀 