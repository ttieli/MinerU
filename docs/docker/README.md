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
```

**4. 依赖冲突**
请参考 [依赖冲突解决方案](#dependency-conflicts) 章节。

## 依赖冲突解决方案 {#dependency-conflicts}

### 🔍 常见冲突类型

1. **PyTorch 版本冲突**
   - VLM 模式要求: `torch>=2.6.0`
   - Pipeline 模式要求: `torch>=2.2.2,!=2.5.0,!=2.5.1,<3`
   - 解决方案: 使用 `torch>=2.6.0,<3`

2. **Transformers 版本冲突**
   - VLM 模式要求: `transformers>=4.51.1`
   - Pipeline 模式要求: `transformers>=4.49.0,!=4.51.0,<5.0.0`
   - 解决方案: 使用 `transformers>=4.51.1,<5.0.0`

### 🛠️ 解决步骤

1. **更新依赖文件**
   ```bash
   cd docker/[版本目录]
   # 编辑 requirements.txt，使用兼容版本
   ```

2. **重新构建镜像**
   ```bash
   docker compose build --no-cache
   docker compose up -d
   ```

3. **验证启动**
   ```bash
   curl http://localhost:8000/health
   ```

## 🎯 最佳实践

### 开发环境
- 使用简化版进行快速开发和测试
- 定期拉取最新镜像
- 配置合适的资源限制

### 生产环境
- 使用完整版以获得最佳性能
- 配置监控和日志收集
- 设置自动重启策略

### 资源管理
- 根据实际负载调整内存和CPU限制
- 定期清理未使用的镜像和容器
- 监控磁盘空间使用情况

## 📝 更新日志

### Docker Compose V2 升级
- 将所有 `docker-compose` 命令更新为 `docker compose`
- 兼容 Docker Desktop 4.42.1+
- 支持最新的 compose 文件格式

### M1 芯片优化
- 优化 ARM64 架构支持
- 解决 PyTorch CPU 版本兼容性
- 改进模块导入路径

### 依赖管理改进
- 统一项目依赖管理策略
- 解决版本冲突问题
- 优化构建速度和镜像大小

---

## 🆘 获取帮助

如果遇到问题，请：

1. 查看 [常见问题](../../docs/FAQ_zh_cn.md)
2. 检查 Docker 日志: `docker compose logs`
3. 提交 Issue 时附上详细的错误信息和系统配置

---

**📍 文档位置**: `docs/docker/README.md`  
**🔄 最后更新**: 2024年12月  
**�� 维护者**: MinerU 团队 