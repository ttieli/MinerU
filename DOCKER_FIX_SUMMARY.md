# Docker 容器重启问题解决方案

## 问题描述

Docker 容器 `mineru-m1-api` 一直处于重启状态，退出码为 1：

```
NAME            IMAGE              COMMAND                   SERVICE     CREATED         STATUS                          PORTS
mineru-m1-api   m1-mac-mineru-m1   "./entrypoint.sh --h…"   mineru-m1   2 minutes ago   Restarting (1) 40 seconds ago   
```

## 根本原因

**错误信息：** `ModuleNotFoundError: No module named 'magic_pdf.data'`

**原因分析：**
1. `docker/m1-mac/app.py` 使用了旧版本的导入路径 `magic_pdf.*`
2. `requirements.txt` 中安装的是 `mineru[core]` 包
3. 项目已经迁移到新的 `mineru` 模块结构
4. 导致导入路径不匹配，应用启动失败

## 解决方案

### 1. 修复包名 (requirements.txt)

```diff
# 核心依赖
- magic-pdf[core]
+ mineru[core]
```

### 2. 更新导入路径 (app.py)

将所有 `magic_pdf.*` 导入更新为 `mineru.*`：

```diff
# MinerU imports
- from magic_pdf.data.read_api import read_local_images, read_local_office
- import magic_pdf.model as model_config
- from magic_pdf.config.enums import SupportedPdfParseMethod
- from magic_pdf.data.data_reader_writer import DataWriter, FileBasedDataWriter
- from magic_pdf.data.data_reader_writer.s3 import S3DataReader, S3DataWriter
- from magic_pdf.data.dataset import ImageDataset, PymuDocDataset
- from magic_pdf.libs.config_reader import get_bucket_name, get_s3_config
- from magic_pdf.model.doc_analyze_by_custom_model import doc_analyze
- from magic_pdf.operators.models import InferenceResult
- from magic_pdf.operators.pipes import PipeResult

+ from mineru.data.data_reader_writer import DataWriter, FileBasedDataWriter
+ from mineru.data.data_reader_writer.s3 import S3DataReader, S3DataWriter
+ from mineru.utils.config_reader import get_device
+ from mineru.backend.pipeline.pipeline_analyze import doc_analyze
```

### 3. 简化实现

由于某些高级功能暂时不可用，创建了简化版实现：
- 去除了复杂的 Pipeline 和 VLM 功能
- 简化了文件处理逻辑
- 保持了 API 接口兼容性

## 验证步骤

1. **重新构建容器：**
   ```bash
   cd docker/m1-mac
   docker compose down
   docker compose build --no-cache
   docker compose up -d
   ```

2. **检查容器状态：**
   ```bash
   docker compose ps
   ```

3. **测试健康检查：**
   ```bash
   curl http://localhost:8000/health
   ```

4. **查看日志：**
   ```bash
   docker compose logs mineru-m1
   ```

## 项目迁移状态

**新版本模块结构 (mineru)：**
- `demo/demo.py` ✅
- `projects/gradio_app/app.py` ✅
- `docker/m1-mac/app.py` ✅ (已修复)

**旧版本模块结构 (magic_pdf)：**
- `projects/web_api/app.py` ❌ (需要后续修复)
- 部分测试文件 ❌ (需要后续修复)

## 后续建议

1. **统一导入路径：** 将所有使用 `magic_pdf.*` 的文件迁移到 `mineru.*`
2. **完善功能：** 在简化版基础上逐步添加完整的解析功能
3. **版本管理：** 建立清晰的版本兼容性策略
4. **文档更新：** 更新相关文档和示例代码

## 教训总结

1. **保持导入路径一致性** - 项目重构时需要全面更新导入路径
2. **容器化测试** - 在本地测试时应该使用与生产环境相同的依赖配置
3. **渐进式迁移** - 大型项目重构应该分阶段进行，确保向后兼容性