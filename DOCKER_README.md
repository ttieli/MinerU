# MinerU Docker 部署指南

## 🚀 快速开始

MinerU 提供了专为**苹果M芯片（M1/M2/M3/M4）**优化的Docker部署方案，包含精简版和全功能版供您选择。

### 一键启动（推荐）

```bash
# 在项目根目录运行，交互式选择版本
./start_mineru_docker.sh

# 或直接指定版本
./start_mineru_docker.sh start lite   # 启动精简版
./start_mineru_docker.sh start full   # 启动全功能版
```

### 手动启动

```bash
# 精简版
cd docker/m1-mac
docker-compose up -d

# 全功能版
cd docker/m1-mac-full
./simple_start.sh
```

## 📊 版本对比

| 特性 | 精简版 (lite) | 全功能版 (full) | 说明 |
|------|---------------|----------------|------|
| **适用场景** | 日常使用，快速解析 | 复杂文档，高精度需求 | |
| **内存需求** | 4GB (实际1-2GB) | 16GB+ (推荐32GB) | 全功能版需要更多内存 |
| **CPU需求** | 2核心 | 4-8核心 | 全功能版利用更多CPU |
| **启动时间** | ~30秒 | ~2-3分钟 | 精简版启动更快 |
| **存储需求** | ~10GB | ~50GB | 全功能版包含更多模型 |
| **API端口** | 8000 | 8008 | 不同端口避免冲突 |
| **GPU支持** | CPU模式 | CPU + MPS加速 | 全功能版支持Apple GPU |
| **基础PDF解析** | ✅ | ✅ | 两版本都支持 |
| **OCR识别** | ✅ 基础 | ✅ 高精度 | 全功能版精度更高 |
| **表格识别** | ❌ | ✅ | 仅全功能版支持 |
| **公式识别** | ❌ | ✅ | 仅全功能版支持 |
| **复杂布局** | 🟡 基础 | ✅ 高级 | 全功能版处理能力更强 |
| **多语言支持** | ✅ 基础 | ✅ 完整 | 全功能版支持更多语言 |

## 🎯 选择建议

### 选择精简版的场景
- ✅ **日常文档处理** - 处理一般的PDF文档
- ✅ **资源受限** - 内存小于8GB的设备
- ✅ **快速验证** - 快速测试和原型开发
- ✅ **简单文档** - 主要是文本内容的PDF
- ✅ **学习测试** - 了解MinerU功能

### 选择全功能版的场景
- ✅ **复杂文档** - 包含表格、公式的学术论文
- ✅ **高精度需求** - 对解析质量有严格要求
- ✅ **生产环境** - 提供稳定的解析服务
- ✅ **批量处理** - 处理大量复杂文档
- ✅ **完整功能** - 需要所有解析功能

## 📋 系统要求

### 通用要求
- **操作系统**: macOS 12.0+（推荐）或Linux ARM64
- **硬件**: Apple Silicon (M1/M2/M3/M4) 芯片
- **软件**: Docker Desktop 4.0+

### 精简版要求
- **内存**: 至少 4GB 可用内存
- **存储**: 至少 10GB 可用空间
- **CPU**: 2核心或以上

### 全功能版要求
- **内存**: 至少 16GB 可用内存（推荐32GB）
- **存储**: 至少 50GB 可用空间
- **CPU**: 4核心或以上（推荐8核心）

## 🛠️ 常用命令

### 版本管理
```bash
# 交互式选择版本启动
./start_mineru_docker.sh

# 启动特定版本
./start_mineru_docker.sh start lite    # 精简版
./start_mineru_docker.sh start full    # 全功能版

# 查看所有版本状态
./start_mineru_docker.sh status
```

### 服务管理
```bash
# 查看特定版本状态
./start_mineru_docker.sh status lite
./start_mineru_docker.sh status full

# 查看日志
./start_mineru_docker.sh logs lite
./start_mineru_docker.sh logs full

# 停止服务
./start_mineru_docker.sh stop lite
./start_mineru_docker.sh stop full

# 重启服务
./start_mineru_docker.sh restart lite
./start_mineru_docker.sh restart full
```

### 测试和清理
```bash
# 运行测试
./start_mineru_docker.sh test lite
./start_mineru_docker.sh test full

# 清理资源
./start_mineru_docker.sh clean lite    # 清理精简版
./start_mineru_docker.sh clean full    # 清理全功能版
./start_mineru_docker.sh clean         # 清理所有版本

# 查看帮助
./start_mineru_docker.sh help
```

## 📡 API 使用

### 访问地址

#### 精简版
- **API服务**: http://localhost:8000
- **API文档**: http://localhost:8000/docs  
- **健康检查**: http://localhost:8000/health

#### 全功能版
- **API服务**: http://localhost:8008
- **API文档**: http://localhost:8008/docs  
- **健康检查**: http://localhost:8008/health
- **监控端口**: http://localhost:8088

### 解析文档示例

```bash
# 精简版 API 调用
curl -X POST "http://localhost:8000/file_parse" \
  -F "file=@document.pdf" \
  -F "parse_method=auto" \
  -F "return_content_list=true"

# 全功能版 API 调用（支持更多功能）
curl -X POST "http://localhost:8008/file_parse" \
  -F "file=@document.pdf" \
  -F "parse_method=auto" \
  -F "enable_table=true" \
  -F "enable_formula=true" \
  -F "return_content_list=true"
```

## ⚙️ 配置说明

### 精简版配置
- **内存限制**: 4GB
- **CPU限制**: 2核心
- **线程数**: 4个CPU线程
- **批处理**: 单文档处理模式
- **功能**: 基础OCR + 简单布局识别

### 全功能版配置
- **内存限制**: 16GB（可调整到32GB+）
- **CPU限制**: 8核心（可调整）
- **GPU支持**: MPS加速
- **功能**: 完整表格识别 + 公式识别 + 高精度OCR
- **工作进程**: 6个（可调整）
- **批处理**: 3个文档并行处理

## 🔍 故障排除

### 常见问题

#### 1. 端口冲突
```bash
# 检查端口占用
lsof -i :8000  # 精简版
lsof -i :8008  # 全功能版

# 杀死占用进程
kill -9 <PID>
```

#### 2. 内存不足
```bash
# 精简版 - 检查内存使用
docker stats

# 全功能版 - 如果内存不够，考虑：
# 1. 增加系统内存
# 2. 调整配置文件中的内存限制
# 3. 减少并发处理数量
```

#### 3. Docker未启动
```bash
# 启动Docker Desktop
open -a Docker

# 检查Docker状态
docker info
```

#### 4. 服务启动失败
```bash
# 查看详细日志
./start_mineru_docker.sh logs [lite|full]

# 重新构建
./start_mineru_docker.sh clean [lite|full]
./start_mineru_docker.sh start [lite|full]
```

### 性能优化

#### 精简版优化
- 确保至少4GB可用内存
- 关闭不必要的后台应用
- 使用SSD存储以提高I/O性能

#### 全功能版优化
- 推荐使用32GB内存
- 启用MPS加速（自动检测）
- 调整工作进程数量匹配CPU核心数
- 使用高速SSD存储

## 📊 性能表现

### 处理速度对比

| 文档类型 | 精简版 | 全功能版 | 质量差异 |
|---------|--------|----------|----------|
| **简单PDF** (1-5页) | 5-15秒 | 8-20秒 | 全功能版质量更高 |
| **复杂PDF** (5-20页) | 20-60秒 | 25-80秒 | 全功能版布局更准确 |
| **表格文档** | 不支持 | 30-120秒 | 仅全功能版支持 |
| **公式文档** | 不支持 | 40-150秒 | 仅全功能版支持 |
| **图像OCR** | 3-10秒/页 | 2-8秒/页 | 全功能版精度更高 |

### 资源使用对比

| 指标 | 精简版 | 全功能版 |
|------|--------|----------|
| **启动内存** | ~500MB | ~2GB |
| **运行内存** | 1-2GB | 4-12GB |
| **峰值内存** | 3GB | 24GB+ |
| **存储空间** | ~10GB | ~50GB |
| **CPU使用** | 30-60% | 40-90% |

## 🔒 安全说明

- 容器以非root用户运行
- 端口仅本地访问（127.0.0.1）
- 数据持久化存储在本地
- 无需外部网络连接（模型本地化）
- 两个版本使用不同端口，可以同时运行

## 📚 目录结构

```
docker/
├── m1-mac/                        # 精简版配置
│   ├── Dockerfile                 # 镜像构建文件
│   ├── docker-compose.yml         # 服务编排文件
│   ├── app.py                     # API应用
│   ├── requirements.txt           # Python依赖
│   ├── magic-pdf-m1.json         # 配置文件
│   └── README.md                  # 详细说明
└── m1-mac-full/                   # 全功能版配置
    ├── Dockerfile                 # 增强镜像构建文件
    ├── docker-compose.yml         # 复杂服务编排
    ├── app_full.py               # 完整API应用
    ├── requirements-full.txt      # 完整依赖列表
    ├── magic-pdf-full.json       # 完整配置文件
    ├── simple_start.sh           # 简化启动脚本
    └── README.md                  # 详细说明
```

## 🚀 快速切换

如果您已经在使用其中一个版本，可以轻松切换到另一个版本：

```bash
# 从精简版切换到全功能版
./start_mineru_docker.sh stop lite
./start_mineru_docker.sh start full

# 从全功能版切换到精简版
./start_mineru_docker.sh stop full  
./start_mineru_docker.sh start lite

# 同时运行两个版本（使用不同端口）
./start_mineru_docker.sh start lite    # 端口8000
./start_mineru_docker.sh start full    # 端口8008
```

## 📞 技术支持

如果遇到问题：

1. 查看本文档的故障排除部分
2. 运行 `./start_mineru_docker.sh help` 查看帮助
3. 查看对应版本目录下的 README.md 详细文档
4. 检查Docker和系统日志

---

**推荐使用方式**: 
- **新用户**: 先试用精简版了解功能
- **高需求用户**: 直接使用全功能版获得最佳效果
- **开发测试**: 精简版用于开发，全功能版用于生产