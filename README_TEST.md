# MinerU 测试程序使用说明

## 🎯 程序目的

`test_mineru.py` 是一个简单的测试程序，用于快速验证 MinerU 的解析功能是否正常工作。

## 🚀 快速使用

### 基础运行
```bash
# 在项目根目录运行
python test_mineru.py
```

### 直接执行（如果有执行权限）
```bash
./test_mineru.py
```

## 📋 测试内容

### 测试功能
1. **CLI 方式测试** - 使用 MinerU 命令行接口
2. **API 方式测试** - 使用 MinerU 内部 API（备用）
3. **自动文件发现** - 自动查找项目中的测试 PDF 文件
4. **结果输出** - 生成解析结果和测试报告

### 测试文件查找顺序
程序会按以下顺序查找测试 PDF 文件：
1. `demo/pdfs/demo1.pdf`
2. `demo/pdfs/demo2.pdf`
3. `demo/pdfs/demo3.pdf`
4. `demo/pdfs/small_ocr.pdf`
5. `tests/unittest/test_data/assets/pdfs/test_01.pdf`
6. `tests/unittest/test_data/assets/pdfs/test_02.pdf`

## 📁 输出结构

测试运行后会在根目录创建 `test_output/` 目录：

```
test_output/
├── parsed_result/          # 解析结果文件
│   ├── *.md               # Markdown 格式文档
│   ├── *.json             # JSON 格式数据
│   └── images/            # 提取的图片
└── test_report.json       # 测试报告
```

## 🧹 自动清理

- **每次运行前**：自动删除 `test_output/` 目录
- **Git 忽略**：`test_output/` 已添加到 `.gitignore`
- **保持项目干净**：不会污染项目结构

## 📊 测试报告

`test_output/test_report.json` 包含：
- 测试时间戳
- 测试结果（成功/失败）
- 系统信息（Python 版本、平台等）

示例报告：
```json
{
  "timestamp": "2024-12-XX T10:30:00",
  "test_results": {
    "cli_test": true
  },
  "system_info": {
    "python_version": "3.10.x",
    "platform": "darwin",
    "cwd": "/path/to/MinerU"
  }
}
```

## 🎯 使用场景

### 开发测试
```bash
# 修改代码后快速验证
python test_mineru.py
```

### 环境验证
```bash
# 新环境部署后验证安装
python test_mineru.py
```

### CI/CD 集成
```bash
# 可集成到自动化测试流程
python test_mineru.py && echo "测试通过"
```

## ⚠️ 注意事项

1. **运行位置**：必须在项目根目录运行
2. **依赖要求**：需要 MinerU 正确安装和配置
3. **测试文件**：需要项目中存在测试 PDF 文件
4. **资源消耗**：解析过程可能消耗一定的 CPU 和内存

## 🔧 故障排除

### 导入错误
```
❌ 导入错误: No module named 'mineru'
```
**解决**：确保在项目根目录运行，或检查 MinerU 安装

### 找不到测试文件
```
❌ 未找到测试 PDF 文件
```
**解决**：
1. 检查 `demo/pdfs/` 目录是否有文件
2. 手动复制测试 PDF 到指定位置
3. 修改 `test_mineru.py` 中的文件路径

### 解析失败
```
❌ 解析过程中出错
```
**解决**：
1. 检查系统资源（内存、磁盘空间）
2. 查看详细错误信息
3. 验证 MinerU 配置是否正确

## 📝 自定义配置

如需自定义测试：

1. **修改测试文件**：编辑 `find_test_pdf()` 函数中的文件路径
2. **调整解析参数**：修改 `test_mineru_basic()` 中的解析选项
3. **自定义输出**：更改 `setup_output_dir()` 中的输出目录名

---

**💡 提示**：这是一个轻量级的测试工具，主要用于快速验证功能。如需完整测试，请使用项目的完整测试套件。 