# MinerU Docker 苹果M芯片配置优化总结

## 🎯 优化目标

检查并优化当前Docker版的苹果M芯片运行配置，删除不必要的内容，保留最靠谱的启动方式和启动脚本在根目录。

**📝 需求调整**: 用户反馈需要同时保留精简版和全功能版，以满足不同的解析需求场景。

## ✅ 已完成的优化

### 1. 保留双版本架构
- ✅ **保留** `docker/m1-mac/` - 精简版配置，适合日常使用
  - 内存需求：4GB限制，实际使用1-2GB
  - CPU模式运行，无需GPU
  - 支持基础PDF解析、OCR识别
  - 配置简洁，启动快速

- ✅ **保留并优化** `docker/m1-mac-full/` - 全功能版配置，最强解析能力
  - 内存需求：16GB+（推荐32GB）
  - 支持MPS加速，完整表格和公式识别
  - 最高精度的文档解析
  - 清理冗余文件，保留核心功能

### 2. 清理冗余配置
- ❌ **删除** `docker/china/` - 中国镜像配置目录  
- ❌ **删除** `docker/global/` - 全球镜像配置目录
- ❌ **删除** `docker/compose.yaml` - 多余的compose文件
- ❌ **删除** 过时的文档文件：
  - `M1_MAC_DOCKER_SUMMARY.md`
  - `DOCKER_COMPARISON.md` 
  - `MinerU_DOCKER_LONG_TERM_SOLUTION.md`

### 3. 优化全功能版配置
- ❌ **删除** 重复的 Dockerfile 文件（backup, enhanced, local等）
- ❌ **删除** 冗余的启动脚本（多个版本的启动方式）
- ❌ **删除** 监控脚本和构建脚本
- ✅ **保留** 核心文件：
  - `Dockerfile` - 核心构建文件
  - `app_full.py` - 完整API应用
  - `simple_start.sh` - 简化启动脚本
  - `magic-pdf-full.json` - 完整配置文件

### 4. 创建统一启动方案
- ✅ **新增** `start_mineru_docker.sh` - 根目录统一启动脚本
  - 支持交互式版本选择
  - 完整的命令支持（start/stop/restart/status/logs/test/clean）
  - 版本管理功能（lite/full）
  - 系统环境检查
  - Apple Silicon优化检测

### 5. 优化文档结构
- ✅ **新增** `DOCKER_README.md` - 包含双版本对比的使用指南
- ✅ **更新** `README.md` - 在本地部署部分增加Docker选项
- ✅ **更新** 优化总结文档

## 📁 优化后的目录结构

```
项目根目录/
├── start_mineru_docker.sh          # 🆕 统一启动脚本（支持版本选择）
├── DOCKER_README.md                 # 🆕 双版本Docker使用指南
├── README.md                        # ✏️ 已更新，增加Docker部署说明
└── docker/
    ├── m1-mac/                      # ✅ 精简版配置 - 日常使用
    │   ├── Dockerfile               # M1优化的Docker镜像
    │   ├── docker-compose.yml       # 服务编排配置
    │   ├── app.py                   # API应用
    │   ├── requirements.txt         # 轻量级依赖
    │   ├── magic-pdf-m1.json       # M1优化配置
    │   ├── entrypoint.sh           # 容器启动脚本
    │   ├── start.sh                # 本地启动脚本  
    │   ├── test_api.py             # API测试脚本
    │   └── README.md               # 详细说明
    └── m1-mac-full/                 # ✅ 全功能版配置 - 最强解析
        ├── Dockerfile               # 完整功能镜像
        ├── docker-compose.yml       # 复杂服务编排
        ├── app_full.py             # 完整API应用
        ├── requirements-full.txt    # 完整依赖列表
        ├── magic-pdf-full.json     # 完整配置文件
        ├── simple_start.sh         # 简化启动脚本
        ├── entrypoint.sh           # 容器启动脚本
        ├── healthcheck.sh          # 健康检查脚本
        └── README.md               # 详细说明
```

## 🚀 推荐使用方式

### 交互式选择版本
```bash
# 在项目根目录运行，交互式选择版本
./start_mineru_docker.sh
```

### 直接指定版本
```bash
# 启动精简版 - 日常使用
./start_mineru_docker.sh start lite

# 启动全功能版 - 最强解析
./start_mineru_docker.sh start full
```

### 版本管理命令
```bash
# 查看所有版本状态
./start_mineru_docker.sh status

# 查看特定版本状态
./start_mineru_docker.sh status lite
./start_mineru_docker.sh status full

# 停止特定版本
./start_mineru_docker.sh stop lite
./start_mineru_docker.sh stop full

# 清理特定版本
./start_mineru_docker.sh clean lite
./start_mineru_docker.sh clean full
```

## 🎯 双版本优势

### 1. 满足不同需求
- **精简版**: 适合日常文档处理，资源占用低
- **全功能版**: 适合复杂文档，解析精度最高
- **灵活选择**: 根据具体文档复杂度选择合适版本

### 2. 资源优化
- **按需使用**: 不需要最强功能时可使用精简版节省资源
- **性能最大化**: 需要最佳效果时使用全功能版
- **同时运行**: 两版本使用不同端口，可以同时运行

### 3. 开发友好
- **开发测试**: 精简版用于快速开发和测试
- **生产环境**: 全功能版用于生产环境
- **平滑升级**: 可以轻松在两个版本间切换

### 4. 维护简化
- **统一入口**: 一个启动脚本管理两个版本
- **清晰区分**: 配置目录和功能明确分离
- **文档完善**: 详细的使用指南和对比说明

## 📊 版本对比总结

| 特性 | 精简版 (lite) | 全功能版 (full) | 使用建议 |
|------|---------------|----------------|----------|
| **内存需求** | 4GB (实际1-2GB) | 16GB+ (推荐32GB) | 根据设备配置选择 |
| **API端口** | 8000 | 8008 | 可同时运行 |
| **启动时间** | ~30秒 | ~2-3分钟 | 精简版更快 |
| **基础解析** | ✅ | ✅ | 两版本都支持 |
| **表格识别** | ❌ | ✅ | 复杂文档需要全功能版 |
| **公式识别** | ❌ | ✅ | 学术论文需要全功能版 |
| **GPU加速** | CPU模式 | MPS加速 | 全功能版性能更强 |
| **适用场景** | 日常文档 | 复杂文档 | 按需选择 |

## ✅ 验证清单

- [x] 保留精简版配置（m1-mac）
- [x] 恢复并优化全功能版配置（m1-mac-full）
- [x] 清理冗余文件和目录
- [x] 创建支持版本选择的统一启动脚本
- [x] 脚本添加执行权限
- [x] 创建双版本对比的使用文档
- [x] 更新主README文档
- [x] 验证文件结构正确

## 🎉 总结

通过此次优化，MinerU的Docker部署方案变得：

### 更灵活
- **双版本选择** - 精简版用于日常，全功能版用于复杂需求
- **统一管理** - 一个脚本管理两个版本
- **按需使用** - 根据文档复杂度和资源情况选择

### 更实用
- **精简版** - 低门槛，快速上手，适合大多数用户
- **全功能版** - 最强解析能力，适合专业用户和复杂文档
- **无冲突** - 不同端口，可以同时运行

### 更清晰
- **明确分工** - 两个版本职责明确，选择简单
- **详细文档** - 完整的对比说明和使用指南
- **简化配置** - 删除冗余，保留核心

现在用户可以根据自己的需求：
- **新手/轻度使用**: `./start_mineru_docker.sh start lite`
- **专业/重度使用**: `./start_mineru_docker.sh start full`
- **灵活选择**: `./start_mineru_docker.sh` 交互式选择

完美满足"有时候需要最强的解析方式"的需求！🎉