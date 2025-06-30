# MinerU Docker 部署指南

## 🚀 快速开始

MinerU 提供了专为**苹果M芯片（M1/M2/M3/M4）**优化的Docker部署方案。

### 一键启动（推荐）

```bash
# 在项目根目录运行
./start_mineru_docker.sh
```

### 手动启动

```bash
# 进入docker配置目录
cd docker/m1-mac

# 启动服务
docker-compose up -d
```

## 📋 系统要求

- **操作系统**: macOS 12.0+（推荐）或Linux ARM64
- **硬件**: Apple Silicon (M1/M2/M3/M4) 芯片
- **内存**: 至少 4GB 可用内存
- **存储**: 至少 10GB 可用空间
- **软件**: Docker Desktop 4.0+

## 🎯 主要特性

- ✅ **M芯片原生支持** - 基于ARM64架构优化
- ✅ **低内存占用** - 4GB内存限制，实际使用1-2GB
- ✅ **CPU模式运行** - 无需GPU，适合所有Mac设备
- ✅ **完整API接口** - RESTful API + Swagger文档
- ✅ **多格式支持** - PDF、Office文档、图像
- ✅ **一键部署** - 自动化构建和启动

## 🛠️ 常用命令

```bash
# 启动服务
./start_mineru_docker.sh start

# 查看状态
./start_mineru_docker.sh status

# 查看日志
./start_mineru_docker.sh logs

# 停止服务
./start_mineru_docker.sh stop

# 重启服务
./start_mineru_docker.sh restart

# 运行测试
./start_mineru_docker.sh test

# 清理资源
./start_mineru_docker.sh clean

# 查看帮助
./start_mineru_docker.sh help
```

## 📡 API 使用

### 访问地址
- **API服务**: http://localhost:8000
- **API文档**: http://localhost:8000/docs  
- **健康检查**: http://localhost:8000/health

### 解析文档示例

```bash
# 解析PDF文件
curl -X POST "http://localhost:8000/file_parse" \
  -F "file=@document.pdf" \
  -F "parse_method=auto" \
  -F "return_content_list=true"

# 解析Office文档
curl -X POST "http://localhost:8000/file_parse" \
  -F "file=@document.docx" \
  -F "parse_method=auto"

# 解析图像文件
curl -X POST "http://localhost:8000/file_parse" \
  -F "file=@image.png" \
  -F "parse_method=ocr"
```

## ⚙️ 配置说明

### 性能配置
- **内存限制**: 4GB（可在docker-compose.yml中调整）
- **CPU限制**: 2核心（可根据设备性能调整）
- **线程数**: 4个CPU线程
- **批处理**: 单文档处理模式

### 功能配置
- **OCR引擎**: PaddleOCR CPU版本
- **布局检测**: YOLO轻量版模型  
- **模型存储**: 持久化本地存储
- **输出格式**: Markdown + JSON + 图像

## 🔍 故障排除

### 常见问题

1. **内存不足**
   ```bash
   # 增加内存限制
   # 编辑 docker/m1-mac/docker-compose.yml
   # 将 memory: 4G 改为 memory: 6G
   ```

2. **端口被占用**
   ```bash
   # 检查端口占用
   lsof -i :8000
   
   # 杀死占用进程
   kill -9 <PID>
   ```

3. **Docker未启动**
   ```bash
   # 启动Docker Desktop
   open -a Docker
   ```

4. **服务启动失败**
   ```bash
   # 查看详细日志
   ./start_mineru_docker.sh logs
   
   # 重新构建
   ./start_mineru_docker.sh clean
   ./start_mineru_docker.sh start
   ```

### 查看日志
```bash
# 实时日志
./start_mineru_docker.sh logs

# 容器状态
docker ps

# 系统资源
docker stats
```

## 📊 性能表现

### 处理速度
- **简单PDF**（1-5页）: 5-15秒
- **复杂PDF**（5-20页）: 20-60秒
- **Office文档**: 10-30秒
- **图像OCR**: 3-10秒/页

### 资源使用
- **内存占用**: 1-2GB（峰值3GB）
- **CPU使用**: 30-60%（4线程）
- **存储占用**: ~5GB（包含基础镜像）

## 🔒 安全说明

- 容器以非root用户运行
- 端口仅本地访问（127.0.0.1）
- 数据持久化存储在本地
- 无需外部网络连接（模型本地化）

## 📚 目录结构

```
docker/
└── m1-mac/                    # M芯片优化配置
    ├── Dockerfile             # 镜像构建文件
    ├── docker-compose.yml     # 服务编排文件
    ├── app.py                 # API应用
    ├── requirements.txt       # Python依赖
    ├── magic-pdf-m1.json     # MinerU配置
    ├── entrypoint.sh         # 容器启动脚本
    ├── start.sh              # 本地启动脚本
    ├── test_api.py           # API测试脚本
    └── README.md             # 详细说明
```

## 📞 技术支持

如果遇到问题：

1. 查看本文档的故障排除部分
2. 查看 `docker/m1-mac/README.md` 详细文档
3. 运行 `./start_mineru_docker.sh help` 查看帮助
4. 检查Docker和系统日志

---

**推荐使用方式**: 直接运行 `./start_mineru_docker.sh` 即可完成所有部署操作！