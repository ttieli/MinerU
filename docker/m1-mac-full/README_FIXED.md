# MinerU M芯片全功能版修复方案

## 🚀 快速开始

这个修复方案解决了原版MinerU Docker配置中的所有问题，提供了稳定可靠的部署方案。

### 一键启动（推荐）
```bash
# 快速启动 - 适合测试和验证
./quick-start.sh

# 完整构建 - 适合生产环境
./build-fixed.sh
```

### 手动启动
```bash
# 1. 创建必要目录
mkdir -p models layoutreader output logs cache config temp

# 2. 构建镜像
docker build -f Dockerfile.fixed -t mineru-m1-full:latest .

# 3. 启动服务
docker-compose -f docker-compose.fixed.yml up -d

# 4. 检查状态
docker-compose -f docker-compose.fixed.yml ps
```

## 📁 文件说明

### 核心文件
- `Dockerfile.fixed` - 修复版Docker镜像构建文件
- `docker-compose.fixed.yml` - 修复版服务编排文件
- `build-fixed.sh` - 完整的自动化构建脚本
- `quick-start.sh` - 快速启动脚本（测试用）

### 配置文件
- `.env` - 环境变量配置（自动生成）
- `magic-pdf-full.json` - MinerU应用配置
- `requirements-full.txt` - Python依赖包
- `constraints.txt` - 版本约束

### 脚本文件
- `entrypoint.sh` - 容器启动脚本
- `healthcheck.sh` - 健康检查脚本
- `download_models_full.py` - 模型下载脚本

## 🔧 主要修复

1. **移除不存在的文件引用** - 修复了原版Dockerfile中引用不存在目录的问题
2. **简化服务配置** - 保留核心功能，移除不必要的复杂配置
3. **优化构建流程** - 分层构建，提高构建效率和稳定性
4. **本地模型支持** - 支持使用已下载的本地模型
5. **自动化脚本** - 提供完整的自动化部署和管理工具

## 📊 服务访问

启动成功后，可以访问以下地址：

- **API服务**: http://localhost:8000
- **API文档**: http://localhost:8000/docs  
- **健康检查**: http://localhost:8000/health
- **状态监控**: http://localhost:8080

## 🛠️ 常用命令

```bash
# 查看服务状态
docker-compose -f docker-compose.fixed.yml ps

# 查看日志
docker-compose -f docker-compose.fixed.yml logs -f mineru-full

# 重启服务
docker-compose -f docker-compose.fixed.yml restart mineru-full

# 停止服务
docker-compose -f docker-compose.fixed.yml down

# 健康检查
curl http://localhost:8000/health
```

## 📝 测试PDF处理

```bash
# 基础测试
curl -X POST http://localhost:8000/parse \
  -F "file=@demo/pdfs/demo1.pdf" \
  -H "Content-Type: multipart/form-data"

# 批量处理
curl -X POST http://localhost:8000/batch_parse \
  -F "files=@demo/pdfs/demo1.pdf" \
  -F "files=@demo/pdfs/demo2.pdf"
```

## 🔍 故障排除

如果遇到问题，请检查：

1. **端口冲突**: 确保8000和8080端口未被占用
2. **内存不足**: 确保系统有足够内存（推荐16GB+）
3. **Docker版本**: 确保Docker和Docker Compose版本最新
4. **权限问题**: 确保脚本有执行权限

查看详细日志：
```bash
docker-compose -f docker-compose.fixed.yml logs mineru-full --tail 50
```

## 📚 详细文档

更详细的部署和配置信息请参考：
- [完整部署指南](COMPLETE_DEPLOYMENT_GUIDE.md)
- [原版构建脚本](build.sh)
- [官方文档](README.md)

---

这个修复方案确保了MinerU全功能版能够在Apple Silicon设备上稳定运行，提供完整的PDF处理能力。