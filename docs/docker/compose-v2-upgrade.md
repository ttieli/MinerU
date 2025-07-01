# Docker Compose V2 升级总结

## 🔄 修改说明

根据您的 Docker Desktop 4.42.1 版本，已将项目中所有的 `docker-compose`（连字符）命令更新为 `docker compose`（空格），以兼容新版 Docker Compose V2。

## 📝 修改的文件

### 1. 核心启动脚本
- `start_mineru_docker.sh` - 修改了 Docker Compose 检测逻辑，优先使用新版命令

### 2. 文档文件
- `DOCKER_README.md` - 更新了所有示例命令
- `projects/mcp/README.md` - 更新 MCP 项目相关命令
- `projects/mcp/DOCKER_README.md` - 更新 MCP Docker 部署指南
- `docker/m1-mac/README.md` - 更新 M1 Mac 简化版文档
- `docker/m1-mac-full/README.md` - 更新 M1 Mac 完整版文档
- `docker/m1-mac-full/DEPLOYMENT_GUIDE.md` - 更新完整版部署指南

### 3. 脚本文件
- `docker/m1-mac-full/start_mineru_full_safe.sh` - 更新安全启动脚本
- `docker/m1-mac-full/monitor-build.sh` - 更新监控构建脚本

## 🔧 主要修改内容

### 原命令 → 新命令
```bash
# 基础命令
docker-compose up -d          → docker compose up -d
docker-compose down           → docker compose down
docker-compose ps             → docker compose ps
docker-compose logs -f        → docker compose logs -f
docker-compose restart        → docker compose restart
docker-compose build          → docker compose build

# 版本检查
docker-compose --version      → docker compose version

# 高级命令
docker-compose --profile production up -d      → docker compose --profile production up -d
docker-compose -f file1.yml -f file2.yml up   → docker compose -f file1.yml -f file2.yml up
docker-compose --scale service=3 up -d        → docker compose --scale service=3 up -d
```

### 启动脚本智能检测
`start_mineru_docker.sh` 现在会：
1. **优先检测** `docker compose` 命令（Docker Compose V2）
2. **回退支持** 旧版 `docker-compose` 命令
3. **提供提示** 建议升级到最新版本

## ✅ 兼容性说明

### Docker Desktop 4.42.1 支持
- ✅ **docker compose** (推荐) - 新版 Compose V2
- ✅ **docker-compose** (兼容) - 旧版 Compose V1
- ✅ **platform 字段** - 完全支持 ARM64/AMD64 指定

### compose.yml 功能支持
- ✅ `platform: linux/arm64` - Apple Silicon 优化
- ✅ `profiles` - 多环境配置
- ✅ `deploy.resources` - 资源限制
- ✅ `healthcheck` - 健康检查
- ✅ `depends_on` - 服务依赖

## 🚀 使用建议

### 推荐用法
```bash
# 进入项目目录
cd MinerU

# 使用一键启动脚本（自动检测）
./start_mineru_docker.sh

# 手动启动（推荐新版命令）
cd docker/m1-mac
docker compose up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f
```

### 最佳实践
1. **优先使用** `docker compose` 命令
2. **定期更新** Docker Desktop 到最新版本
3. **检查兼容性** 在 CI/CD 中使用时确认版本支持

## 📋 验证修改

### 测试命令
```bash
# 检查 Docker Compose 版本
docker compose version

# 验证 compose 文件语法
docker compose config

# 启动服务测试
docker compose up -d
docker compose ps
docker compose down
```

### 预期结果
- ✅ 所有命令正常执行
- ✅ 不出现 "platform field not supported" 错误
- ✅ 服务正常启动和停止

## 🎯 总结

本次修改确保了 MinerU 项目与最新的 Docker Desktop 4.42.1 版本完全兼容，所有用户现在都可以：

1. **无缝使用** 最新的 Docker Compose V2 命令
2. **享受性能提升** 新版本带来的速度和稳定性改进  
3. **避免兼容性问题** 不再出现 platform 字段错误
4. **保持向后兼容** 旧版本用户仍可正常使用

---

**✨ 现在您可以使用 `docker compose up -d` 命令启动 MinerU 服务了！**