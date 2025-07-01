# MinerU 依赖冲突完整分析与解决方案

## 🔍 问题概述

在 Docker M1-Mac 环境中构建时出现依赖版本冲突，主要体现在 PyTorch、Transformers 等核心 AI 库的版本约束上。

## 📊 详细冲突分析

### 1. PyTorch 版本冲突

**冲突详情:**
- **VLM 模式要求**: `torch>=2.6.0`
- **Pipeline 模式要求**: `torch>=2.2.2,!=2.5.0,!=2.5.1,<3`
- **当前 M1-Mac**: `torch>=2.2.2,<3,!=2.5.0,!=2.5.1`

**解决方案**: 需要使用 `torch>=2.6.0,<3` 来同时满足两个模式的要求。

### 2. Transformers 版本冲突

**冲突详情:**
- **VLM 模式要求**: `transformers>=4.51.1`
- **Pipeline 模式要求**: `transformers>=4.49.0,!=4.51.0,<5.0.0`
- **当前 M1-Mac**: `transformers>=4.35.2`

**关键问题**: VLM 要求 `>=4.51.1`，而 Pipeline 排除了 `4.51.0`，所以需要 `>=4.51.1` 才能同时满足。

### 3. 其他版本问题

- **NumPy**: 固定版本 `1.24.4` 过于严格，应使用范围约束
- **HuggingFace Hub**: 版本过低，需要更新以支持新功能
- **依赖管理策略**: 混合使用 `mineru[core]` 和具体包可能导致冲突

## 🛠️ 解决方案

### 方案 1: 兼容性优先 (推荐)

更新 `docker/m1-mac/requirements.txt` 使其与 pyproject.toml 完全兼容：

```txt
# 核心依赖 - 完全兼容版本
mineru[core]

# API服务
fastapi>=0.104.1
uvicorn[standard]>=0.24.0
python-multipart

# 基础依赖
requests
loguru>=0.7.2

# 图像处理
Pillow>=11.0.0
opencv-python-headless>=4.8.1.78

# 科学计算 (兼容 VLM + Pipeline)
torch>=2.6.0,<3
torchvision>=0.17.0

# HTTP客户端
httpx>=0.25.2

# HuggingFace (兼容版本)
huggingface-hub>=0.32.4
transformers>=4.51.1,<5.0.0

# 数学库 (范围约束而非固定版本)
numpy>=1.24.4,<2.0.0
```

### 方案 2: 最小化依赖

如果只需要基础功能，可以不使用 `mineru[core]`，而是精确指定需要的功能：

```txt
# 基础 MinerU (不包含 VLM)
mineru[pipeline]

# API服务
fastapi
uvicorn[standard]
python-multipart

# 其他必需依赖...
```

### 方案 3: 分阶段构建

在 Dockerfile 中使用多阶段构建，先解决依赖冲突：

```dockerfile
# 第一阶段：解决依赖
FROM python:3.10-slim as deps
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 第二阶段：应用构建
FROM python:3.10-slim
COPY --from=deps /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
# ... 其他构建步骤
```

## 🔧 具体修复步骤

### 立即修复

1. **更新 PyTorch 版本约束**
2. **更新 Transformers 版本约束**
3. **放宽 NumPy 版本约束**
4. **统一依赖管理策略**

### 验证步骤

1. 在本地测试依赖解析：
   ```bash
   pip install -r docker/m1-mac/requirements.txt --dry-run
   ```

2. Docker 构建测试：
   ```bash
   cd docker/m1-mac && docker build -t mineru-m1-test .
   ```

3. 功能验证：
   ```bash
   docker run mineru-m1-test mineru --help
   ```

## 📈 长期优化建议

### 1. 依赖版本策略

- **使用范围约束**而不是固定版本
- **定期更新依赖**以获得安全修复
- **使用依赖锁定文件**在生产环境

### 2. 自动化测试

- **CI/CD 中增加依赖冲突检测**
- **多环境兼容性测试**
- **定期依赖安全扫描**

### 3. 文档改进

- **明确各模式的最低系统要求**
- **提供依赖故障排除指南**
- **维护兼容性矩阵**

## 🚨 注意事项

1. **M1/ARM64 兼容性**: 确保所有依赖都支持 ARM64 架构
2. **内存使用**: 较新版本的库可能需要更多内存
3. **向后兼容**: 版本升级可能影响现有模型的兼容性
4. **构建时间**: 版本冲突解决可能增加构建时间

## ✅ 验证清单

- [ ] PyTorch 版本 >= 2.6.0
- [ ] Transformers 版本 >= 4.51.1, < 5.0.0
- [ ] NumPy 版本使用范围约束
- [ ] HuggingFace Hub 版本 >= 0.32.4
- [ ] Docker 构建成功
- [ ] 基础功能测试通过
- [ ] 内存使用在合理范围内

---

**状态**: 🔄 需要应用解决方案
**优先级**: 🔴 高
**影响范围**: Docker M1-Mac 环境