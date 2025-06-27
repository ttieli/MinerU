# MinerU 模型信息说明

本文档说明了MinerU M1 Mac Docker版本中使用的模型及其在容器内的运行情况。

## 模型概览

### 核心模型（在Docker内运行）

以下模型**需要在Docker容器内运行**，已经过M1芯片CPU优化：

#### 1. 布局检测模型 (Layout Detection)
- **模型名称**: YOLO-based Document Layout Detection
- **路径**: `/opt/models/Layout/YOLO/`
- **功能**: 检测文档的布局结构（标题、段落、图片、表格等）
- **运行环境**: CPU模式，4线程优化
- **内存占用**: ~200MB

#### 2. 公式检测模型 (Mathematical Formula Detection)
- **模型名称**: YOLO MFD (Mathematical Formula Detection)
- **路径**: `/opt/models/MFD/YOLO/`
- **功能**: 检测文档中的数学公式区域
- **运行环境**: CPU模式
- **内存占用**: ~150MB

#### 3. OCR识别模型 (Optical Character Recognition)
- **模型名称**: PaddleOCR PyTorch版本
- **路径**: `/opt/models/OCR/paddleocr_torch/`
- **功能**: 文字识别和文本提取
- **运行环境**: CPU模式，支持多语言
- **内存占用**: ~300MB

#### 4. 布局阅读器 (Layout Reader)
- **模型名称**: LayoutReader
- **路径**: `/opt/layoutreader/`
- **功能**: 阅读顺序识别和排序
- **运行环境**: CPU模式
- **内存占用**: ~100MB

## 模型下载策略

### 轻量级下载
为了减少Docker镜像大小和内存占用，我们采用了以下策略：

1. **只下载核心模型**: 仅包含PDF解析必需的基础模型
2. **排除可选模型**: 暂时禁用表格识别等高内存消耗的功能
3. **使用临时缓存**: 下载过程中使用临时目录，完成后清理

### 被禁用的模型
以下模型已被**禁用**以节省内存和存储空间：

- ❌ **表格识别模型** (Table Recognition): 内存占用过高
- ❌ **公式识别模型** (Mathematical Formula Recognition): 可选功能
- ❌ **LayoutLM模型**: 已有YOLO替代方案
- ❌ **TableMaster**: 表格功能已禁用
- ❌ **StructEqTable**: 表格结构识别已禁用

## 内存使用优化

### CPU模式配置
```json
{
    "device-mode": "cpu",
    "performance-config": {
        "max_workers": 2,
        "batch_size": 1,
        "memory_limit": "2GB"
    }
}
```

### 线程限制
```bash
TORCH_NUM_THREADS=4
OMP_NUM_THREADS=4
MKL_NUM_THREADS=4
```

### OCR优化设置
```json
{
    "ocr-config": {
        "use_angle_cls": false,
        "det_limit_side_len": 960,
        "det_limit_type": "min"
    }
}
```

## 模型加载时机

### 延迟加载
- 模型在**首次使用时**才加载到内存
- 减少容器启动时间和内存占用
- 支持模型卸载以释放内存

### 预加载检查
容器启动时会检查模型文件完整性：
```bash
# 检查模型目录
ls -la /opt/models/Layout/YOLO/
ls -la /opt/models/MFD/YOLO/
ls -la /opt/models/OCR/paddleocr_torch/
ls -la /opt/layoutreader/
```

## 性能基准测试

### 典型文档处理时间
- **简单PDF** (1-5页): 5-15秒
- **复杂PDF** (5-20页): 20-60秒
- **图像OCR**: 3-10秒/页

### 内存使用情况
- **空闲状态**: ~500MB
- **处理中**: 1-2GB
- **峰值使用**: 最大3GB

### CPU使用情况
- **M1芯片**: 高效能核心和高性能核心
- **线程分配**: 最多4个线程
- **平均CPU使用率**: 30-60%

## 故障排除

### 模型下载失败
```bash
# 手动重新下载
docker exec mineru-m1-api python download_models_light.py

# 使用国内镜像源
docker run -e MINERU_MODEL_SOURCE=modelscope mineru-m1:latest
```

### 内存不足
```bash
# 增加容器内存限制
docker run --memory=6g mineru-m1:latest

# 或者修改docker-compose.yml中的memory限制
```

### 模型加载错误
```bash
# 检查模型文件
docker exec mineru-m1-api find /opt -name "*.pth" -o -name "*.safetensors"

# 清理并重新下载
docker exec mineru-m1-api rm -rf /opt/models/*
docker restart mineru-m1-api
```

## 模型更新

### 自动更新
容器启动时会检查模型版本，如需要会自动下载最新版本。

### 手动更新
```bash
# 进入容器
docker exec -it mineru-m1-api bash

# 删除旧模型
rm -rf /opt/models/*

# 重新下载
python download_models_light.py

# 重启服务
exit
docker restart mineru-m1-api
```

## 模型许可证

所有使用的模型均遵循其原始许可证：
- **PaddleOCR**: Apache 2.0
- **YOLO**: GPL-3.0
- **LayoutReader**: MIT
- **PDF-Extract-Kit**: Apache 2.0

## 技术支持

如遇到模型相关问题，请：
1. 检查Docker容器日志
2. 验证模型文件完整性
3. 确认内存和CPU资源充足
4. 提交Issue并附上错误日志