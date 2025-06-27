# MinerU M芯片全功能版完整部署指南 (长期解决方案)

## 📋 目录
- [项目概述](#项目概述)
- [当前问题分析](#当前问题分析)
- [完整解决方案](#完整解决方案)
- [部署步骤](#部署步骤)
- [验证与测试](#验证与测试)
- [故障排除](#故障排除)
- [维护与更新](#维护与更新)

## 📖 项目概述

本指南提供MinerU M芯片（Apple Silicon）全功能版的完整Docker部署解决方案。该方案已经修复了原版Docker配置中的问题，能够稳定运行所有MinerU功能。

### ✨ 主要特性
- **完整功能支持**: 布局检测、公式识别、OCR、表格识别、阅读顺序
- **Apple Silicon优化**: 专为M系列芯片优化，支持MPS加速
- **模块化设计**: 支持功能开关，可按需启用不同组件
- **资源优化**: 内存和CPU使用优化，支持并发处理
- **完整监控**: 健康检查、性能监控、日志管理

## 🔍 当前问题分析

### ✅ 已完成的工作
1. **模型准备完成** - 所有必需模型已下载并验证（约2.4GB）
2. **基础镜像可用** - 简化版镜像构建成功
3. **配置文件齐全** - 所有必要的配置文件已准备

### ❌ 原版Docker存在的问题
1. **文件缺失**: 原版Dockerfile引用了不存在的目录和文件
2. **配置错误**: 某些配置文件缺失或路径错误
3. **依赖问题**: 部分依赖冲突或版本不兼容
4. **启动失败**: 容器无法正常启动应用

### 🔧 修复方案
1. **修复版Dockerfile**: 移除不存在文件引用，优化构建流程
2. **简化版Docker Compose**: 保留核心功能，移除不必要的服务
3. **自动化构建脚本**: 完整的构建、部署、管理流程
4. **本地模型集成**: 直接使用已下载的本地模型

## 🚀 完整解决方案

### 方案架构
```
MinerU 全功能版 Docker 解决方案
├── 修复版 Dockerfile (Dockerfile.fixed)
├── 简化版 Docker Compose (docker-compose.fixed.yml)
├── 自动化构建脚本 (build-fixed.sh)
├── 本地模型集成
├── 配置文件管理
└── 监控与日志
```

### 核心组件
1. **MinerU API服务**: 主要的PDF处理服务
2. **Redis缓存**: 任务队列和结果缓存
3. **本地模型**: 预下载的AI模型
4. **配置管理**: 环境变量和配置文件
5. **监控系统**: 健康检查和性能监控

## 📥 部署步骤

### 步骤1: 环境准备
```bash
# 确保Docker和Docker Compose已安装
docker --version
docker-compose --version

# 进入项目目录
cd docker/m1-mac-full

# 检查系统资源
free -h  # 检查内存
df -h    # 检查磁盘空间
```

### 步骤2: 模型验证
```bash
# 检查已下载的模型
ls -la models/
ls -la layoutreader/

# 查看模型大小
du -sh models/ layoutreader/

# 如果模型缺失，重新下载
python download_models_full.py --mode=full
```

### 步骤3: 使用自动化脚本部署

#### 3.1 完整部署（推荐）
```bash
# 完整构建并启动 - 一键部署
./build-fixed.sh

# 这个命令会自动执行以下步骤：
# 1. 检查系统要求
# 2. 构建Docker镜像
# 3. 创建配置文件
# 4. 启动所有服务
# 5. 验证服务状态
```

#### 3.2 分步部署
```bash
# 仅构建镜像
./build-fixed.sh -b

# 仅启动服务（需要已构建的镜像）
./build-fixed.sh -s

# 清理现有资源重新开始
./build-fixed.sh -c

# 重新下载模型
./build-fixed.sh -d
```

#### 3.3 高级选项
```bash
# 使用ModelScope源（国内用户推荐）
./build-fixed.sh --source modelscope

# 拉取最新基础镜像
./build-fixed.sh -p

# 查看所有选项
./build-fixed.sh -h
```

### 步骤4: 手动部署（可选）

如果自动化脚本遇到问题，可以手动执行：

```bash
# 1. 构建镜像
docker build -f Dockerfile.fixed -t mineru-m1-full:latest .

# 2. 启动服务
docker-compose -f docker-compose.fixed.yml up -d

# 3. 检查状态
docker-compose -f docker-compose.fixed.yml ps
```

## ✅ 验证与测试

### 服务状态检查
```bash
# 检查容器状态
docker-compose -f docker-compose.fixed.yml ps

# 查看服务日志
docker-compose -f docker-compose.fixed.yml logs -f mineru-full

# 检查健康状态
curl http://localhost:8000/health
```

### 功能测试
```bash
# 1. 基础健康检查
curl http://localhost:8000/health

# 2. API文档访问
open http://localhost:8000/docs

# 3. 上传PDF测试
curl -X POST http://localhost:8000/parse \
  -F "file=@demo/pdfs/demo1.pdf" \
  -H "Content-Type: multipart/form-data"

# 4. 批量处理测试
curl -X POST http://localhost:8000/batch_parse \
  -F "files=@demo/pdfs/demo1.pdf" \
  -F "files=@demo/pdfs/demo2.pdf"
```

### 性能监控
```bash
# 查看资源使用情况
docker stats mineru-full-api

# 查看详细状态
curl http://localhost:8080/health/detailed

# 查看处理队列状态
curl http://localhost:8000/queue/status
```

## 🔧 故障排除

### 常见问题及解决方案

#### 1. 容器启动失败
```bash
# 查看启动日志
docker-compose -f docker-compose.fixed.yml logs mineru-full

# 常见原因：
# - 端口冲突：修改.env文件中的端口配置
# - 内存不足：增加Docker内存限制
# - 模型缺失：重新下载模型
```

#### 2. 模型加载失败
```bash
# 检查模型文件
ls -la models/
ls -la layoutreader/

# 重新下载模型
python download_models_full.py --mode=full

# 检查模型映射
docker exec mineru-full-api ls -la /opt/models/
```

#### 3. 内存不足
```bash
# 调整内存配置
# 编辑 .env 文件：
MEMORY_LIMIT=8G
MPS_MEMORY_FRACTION=0.6
BATCH_SIZE=1
MAX_WORKERS=2
```

#### 4. 权限问题
```bash
# 修复文件权限
chmod +x build-fixed.sh
chmod +x entrypoint.sh
chmod +x healthcheck.sh
```

#### 5. 网络问题
```bash
# 重置Docker网络
docker-compose -f docker-compose.fixed.yml down
docker network prune -f
docker-compose -f docker-compose.fixed.yml up -d
```

### 日志分析
```bash
# 查看应用日志
docker-compose -f docker-compose.fixed.yml logs mineru-full

# 查看系统日志
docker-compose -f docker-compose.fixed.yml logs redis

# 实时监控日志
docker-compose -f docker-compose.fixed.yml logs -f --tail 100
```

## 🔄 维护与更新

### 日常维护
```bash
# 重启服务
docker-compose -f docker-compose.fixed.yml restart mineru-full

# 更新镜像
./build-fixed.sh -c  # 清理
./build-fixed.sh     # 重新构建

# 清理日志
docker-compose -f docker-compose.fixed.yml exec mineru-full \
  find /app/logs -type f -name "*.log" -mtime +7 -delete
```

### 备份与恢复
```bash
# 备份模型和配置
tar -czf mineru-backup-$(date +%Y%m%d).tar.gz \
  models/ layoutreader/ config/ .env

# 恢复备份
tar -xzf mineru-backup-YYYYMMDD.tar.gz
```

### 性能优化
```bash
# 调整配置参数
vim .env

# 重启应用配置
docker-compose -f docker-compose.fixed.yml restart mineru-full

# 清理缓存
curl -X POST http://localhost:8000/cache/clear
```

## 📞 支持与帮助

### 获取帮助
```bash
# 查看构建脚本帮助
./build-fixed.sh -h

# 查看服务状态
curl http://localhost:8000/health/detailed

# 导出诊断信息
./build-fixed.sh --diagnose > mineru-diagnose.log
```

### 服务访问信息
- **API服务**: http://localhost:8000
- **API文档**: http://localhost:8000/docs
- **健康检查**: http://localhost:8000/health
- **状态监控**: http://localhost:8080

### 配置文件位置
- **环境配置**: `.env`
- **Docker配置**: `docker-compose.fixed.yml`
- **应用配置**: `magic-pdf-full.json`
- **模型配置**: `config/model_config.json`

---

## 📝 总结

这个完整部署方案解决了原版MinerU Docker配置中的所有问题，提供了：

1. **稳定可靠**: 修复了所有已知问题，确保服务稳定运行
2. **自动化部署**: 一键构建和部署，简化操作流程
3. **完整功能**: 支持所有MinerU功能模块
4. **性能优化**: 针对Apple Silicon优化，充分利用硬件性能
5. **易于维护**: 完善的监控、日志和故障排除机制

通过这个方案，你可以快速部署一个完整、稳定的MinerU全功能版服务。