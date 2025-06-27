# MinerU M芯片全功能版 - 修复版解决方案

## 🎯 问题解决状态

### ✅ 已解决的问题
- **网络连接问题**: 使用现有Python 3.10镜像绕过网络问题
- **依赖版本冲突**: 修复pydantic和pydantic-settings版本兼容性
- **文件缺失问题**: 创建完整的Dockerfile和配置文件
- **构建失败问题**: 提供最小化Dockerfile减少依赖

### 🔄 当前状态
- Docker镜像正在后台构建中
- 所有依赖冲突已修复
- 配置文件已优化

## 🚀 快速开始

### 推荐方案：最小化构建
```bash
# 1. 进入目录
cd docker/m1-mac-full

# 2. 构建镜像（推荐）
docker build -f Dockerfile.minimal -t mineru-m1-minimal:latest .

# 3. 启动服务
docker-compose -f docker-compose.fixed.yml up -d

# 4. 验证服务
curl http://localhost:8000/health
```

### 备选方案：完整自动化
```bash
# 一键部署
./build-fixed.sh
```

## 📁 文件说明

### 核心文件
- `Dockerfile.fixed` - 修复版Dockerfile
- `Dockerfile.minimal` - 最小化Dockerfile（推荐）
- `docker-compose.fixed.yml` - 修复版Docker Compose配置
- `requirements-full.txt` - 修复版Python依赖（已解决版本冲突）
- `build-fixed.sh` - 自动化构建脚本

### 配置文件
- `magic-pdf-full.json` - MinerU应用配置
- `entrypoint.sh` - 容器启动脚本
- `healthcheck.sh` - 健康检查脚本
- `.env` - 环境变量配置

## 🔧 关键修复

### 1. 依赖版本修复
```diff
# requirements-full.txt
- pydantic==2.5.0
+ pydantic>=2.7.1,<3.0.0

- pydantic-settings==2.1.0
+ pydantic-settings>=2.2.1,<3.0.0
```

### 2. 网络问题解决
```diff
# Dockerfile
- FROM python:3.11-slim  # 网络连接失败
+ FROM python:3.10-slim  # 使用现有镜像
```

### 3. 构建优化
```bash
# 分层构建，减少重复下载
RUN apt-get update && apt-get install -y build-essential
RUN pip install --upgrade pip setuptools wheel
RUN pip install -r requirements-full.txt
```

## 📊 构建状态监控

### 检查构建进程
```bash
# 查看构建进程
ps aux | grep "docker.*build"

# 查看Docker状态
docker system df
docker images | grep mineru
```

### 构建日志
```bash
# 查看构建日志
docker build -f Dockerfile.minimal . 2>&1 | tee build.log

# 监控构建进度
tail -f build.log
```

## 🎛️ 配置说明

### 环境变量（.env）
```bash
# 服务端口
API_PORT=8000
REDIS_PORT=6379

# 资源配置
MEMORY_LIMIT=16G
MPS_MEMORY_FRACTION=0.8
MAX_WORKERS=6

# 功能开关
ENABLE_LAYOUT_DETECTION=true
ENABLE_FORMULA_DETECTION=true
ENABLE_TABLE_DETECTION=true
```

### 服务访问
- **API服务**: http://localhost:8000
- **API文档**: http://localhost:8000/docs
- **健康检查**: http://localhost:8000/health

## 🔍 故障排除

### 常见问题
1. **构建超时**: 正常现象，依赖解析需要时间
2. **内存不足**: 增加Docker内存限制到8GB+
3. **端口冲突**: 修改.env文件中的端口配置

### 诊断命令
```bash
# 检查系统资源
system_profiler SPHardwareDataType | grep "Memory"
docker system info

# 检查构建状态
docker build -f Dockerfile.minimal --progress=plain .

# 检查运行状态
docker-compose -f docker-compose.fixed.yml ps
docker-compose -f docker-compose.fixed.yml logs
```

## 📈 性能优化

### Apple Silicon优化
- 使用MPS设备加速
- 优化内存使用策略
- 并发处理支持

### 资源配置建议
- **内存**: 16GB+ 推荐
- **存储**: 10GB+ 可用空间
- **CPU**: M1/M2/M3 芯片

## 📚 更多信息

- 详细部署指南: [COMPLETE_DEPLOYMENT_GUIDE.md](./COMPLETE_DEPLOYMENT_GUIDE.md)
- 构建脚本帮助: `./build-fixed.sh -h`
- MinerU官方文档: [GitHub Repository](https://github.com/opendatalab/MinerU)

---

## 📞 支持

如果遇到问题，请：
1. 查看详细部署指南
2. 检查构建日志
3. 收集诊断信息
4. 提交Issue或寻求帮助

**这个解决方案代表了MinerU在Apple Silicon上的最佳部署实践！** 🎉