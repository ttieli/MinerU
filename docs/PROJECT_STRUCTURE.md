# MinerU 项目结构说明

## 📁 根目录结构

```
MinerU/
├── 📄 README.md                    # 项目主介绍文档
├── 🚀 QUICK_START.md               # 快速启动指南
├── ⚙️ start_mineru_docker.sh       # 一键启动脚本
├── 📜 pyproject.toml               # Python项目配置
├── 📝 requirements-qa.txt          # QA环境依赖
│
├── 🐍 mineru/                      # 核心Python包
│   ├── backend/                    # 后端处理模块
│   ├── model/                      # AI模型实现
│   ├── utils/                      # 工具函数
│   └── cli/                        # 命令行接口
│
├── 🐳 docker/                      # Docker容器配置
│   ├── m1-mac/                     # Apple Silicon简化版
│   ├── m1-mac-full/                # Apple Silicon完整版
│   ├── china/                      # 中国区配置
│   └── global/                     # 全球配置
│
├── 🧪 tests/                       # 测试文件集合
│   ├── integration/                # 集成测试
│   ├── deployment/                 # 部署测试
│   ├── comparison/                 # 版本对比测试
│   └── unittest/                   # 单元测试
│
├── 📚 docs/                        # 项目文档
│   ├── deployment/                 # 部署相关文档
│   ├── troubleshooting/            # 故障排除指南
│   ├── api/                        # API使用文档
│   └── images/                     # 文档图片资源
│
├── 🚀 projects/                    # 子项目和应用
│   ├── gradio_app/                 # Gradio Web界面
│   ├── web_api/                    # Web API服务
│   └── mcp/                        # MCP集成
│
├── 🎯 demo/                        # 演示文件
│   └── pdfs/                       # 示例PDF文件
│
└── 🔐 signatures/                  # 签名和许可文件
    └── version1/                   # 版本1许可
```

## 🐳 Docker配置详解

### Apple Silicon 版本

#### 简化版 (`docker/m1-mac/`)
- **目标用户**: 日常使用，资源受限环境
- **内存需求**: 8GB
- **功能**: PDF解析、OCR、基础表格识别
- **端口**: 8000

#### 完整版 (`docker/m1-mac-full/`)
- **目标用户**: 专业使用，高精度需求
- **内存需求**: 16GB+
- **功能**: VLM多模态、高级表格识别、公式识别
- **端口**: 8001

### 关键配置文件
```
docker/m1-mac-full/
├── Dockerfile-fixed            # 修复版Dockerfile
├── docker-compose-fixed.yml    # 完整版编排配置
├── app_full.py                 # 完整版应用入口
└── entrypoint.sh              # 容器启动脚本
```

## 🧪 测试体系

### 集成测试 (`tests/integration/`)
- `test_mineru.py` - 基础功能测试

### 部署测试 (`tests/deployment/`)
- `test_full_deployment.py` - 完整部署验证
- `deployment_test_results.json` - 测试结果

### 版本对比测试 (`tests/comparison/`)
- `version_comparison_test.py` - 版本对比脚本
- `version_comparison_results/` - 对比结果目录

## 📚 文档体系

### 快速入门
- `QUICK_START.md` - 一键启动指南
- `README.md` - 项目总览

### 部署文档 (`docs/deployment/`)
- `DEPLOYMENT_STATUS.md` - 部署状态说明
- `VERSION_COMPARISON_CONTENT.md` - 版本对比详情

### API文档 (`docs/api/`)
- API使用指南和参考

### 故障排除 (`docs/troubleshooting/`)
- 常见问题解决方案

## 🔧 核心组件

### 后端处理 (`mineru/backend/`)
```
backend/
├── pipeline/                   # 处理流水线
│   ├── pipeline_analyze.py     # 分析管道
│   ├── model_json_to_middle_json.py  # 模型输出转换
│   └── pipeline_middle_json_mkcontent.py  # 内容生成
└── vlm/                       # 视觉语言模型
    ├── vlm_analyze.py         # VLM分析
    └── token_to_middle_json.py # 令牌转换
```

### AI模型 (`mineru/model/`)
```
model/
├── layout/                    # 布局检测
├── ocr/                      # 光学字符识别
├── mfd/                      # 数学公式检测
├── table/                    # 表格识别
└── reading_order/            # 阅读顺序
```

### 工具函数 (`mineru/utils/`)
```
utils/
├── pdf_reader.py             # PDF读取
├── config_reader.py          # 配置读取
├── language.py               # 语言检测
└── format_utils.py           # 格式工具
```

## 🚀 启动流程

### 自动启动
```bash
./start_mineru_docker.sh
```

### 手动启动
```bash
# 简化版
docker compose -f docker/m1-mac/docker-compose.yml up -d

# 完整版  
docker compose -f docker/m1-mac-full/docker-compose-fixed.yml up -d
```

## 📊 功能对比

| 组件 | 简化版 | 完整版 |
|------|--------|--------|
| **PDF解析** | ✅ | ✅ |
| **OCR识别** | 基础 | 增强 |
| **表格识别** | 基础 | 高级 |
| **公式识别** | ❌ | ✅ |
| **多模态VLM** | ❌ | ✅ |
| **内存占用** | ~4GB | ~16GB |
| **启动时间** | 快 | 慢 |

## 🛠️ 开发指南

### 添加新功能
1. 在 `mineru/` 下添加核心逻辑
2. 在 `tests/` 下添加对应测试
3. 更新 `docker/` 配置（如需要）
4. 更新文档

### 调试技巧
```bash
# 查看容器日志
docker compose logs -f

# 进入容器调试
docker exec -it mineru-api bash

# 查看资源使用
docker stats
```

### 配置修改
- 环境变量: 在对应的 `.env` 文件中修改
- Docker配置: 修改 `docker-compose.yml` 文件
- 应用配置: 修改 `magic-pdf.json` 配置文件

---

📝 **说明**: 本文档描述了MinerU项目的整体结构，帮助开发者和用户快速理解项目组织方式。