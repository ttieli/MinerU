# MinerU 测试套件

本目录包含MinerU项目的完整测试体系，确保双版本Docker系统的稳定性和功能完整性。

## 📁 目录结构

```
tests/
├── integration/           # 集成测试
│   └── test_mineru.py    # 基础功能测试
├── deployment/           # 部署测试  
│   ├── test_full_deployment.py      # 完整部署验证
│   └── deployment_test_results.json # 测试结果
├── comparison/           # 版本对比测试
│   ├── version_comparison_test.py   # 对比测试脚本
│   └── version_comparison_results/  # 对比结果
└── unittest/             # 单元测试 (原有)
    └── ...              # 现有单元测试
```

## 🧪 测试类型

### 1. 集成测试 (`integration/`)

**test_mineru.py**
- 测试基础API功能
- 验证PDF解析流程
- 检查简化版服务状态

```bash
# 运行集成测试
cd tests/integration
python test_mineru.py
```

### 2. 部署测试 (`deployment/`)

**test_full_deployment.py**
- 完整的从零构建测试
- 验证Docker配置正确性
- 确保所有手工修复已固化
- 双版本并行运行测试

```bash
# 运行部署测试
cd tests/deployment  
python test_full_deployment.py
```

测试阶段：
1. 检查Docker状态
2. 清理现有容器
3. 构建镜像
4. 启动服务
5. 健康检查
6. 功能测试
7. 性能对比

### 3. 版本对比测试 (`comparison/`)

**version_comparison_test.py**
- 同一PDF在两版本间的对比
- 性能指标分析
- 内容质量评估
- 功能差异验证

```bash
# 运行对比测试
cd tests/comparison
python version_comparison_test.py
```

对比维度：
- 处理时间
- 内容长度
- 公式识别数量
- 输出质量

## 📊 测试结果示例

### 部署测试结果
```json
{
  "test_time": "2025-07-02T14:21:18",
  "overall_status": "success",
  "phases": {
    "build": {
      "full_version": {
        "status": "success", 
        "duration": 12.41
      }
    },
    "functionality": {
      "simplified": {
        "processing_time": 7.14,
        "content_length": 5552
      },
      "full": {
        "processing_time": 66.38,
        "content_length": 6711
      }
    }
  }
}
```

### 版本对比结果
```json
{
  "time_difference": 59.24,
  "content_enhancement": 1.21,
  "formula_count": {
    "simplified": 0,
    "full": 76
  }
}
```

## 🎯 测试目标

### 质量保证
- ✅ 确保双版本稳定运行
- ✅ 验证配置文件正确性
- ✅ 检查资源使用合理性
- ✅ 确认功能完整性

### 性能验证
- ⏱️ 监控启动时间
- 💾 检查内存使用
- 🔄 验证处理性能
- 📊 对比版本差异

### 部署验证
- 🐳 Docker镜像构建成功
- 🔧 配置文件应用正确
- 🌐 网络端口无冲突
- 📁 数据卷映射正常

## 🔧 运行所有测试

```bash
# 从项目根目录运行
cd "/Users/tieli/Library/Mobile Documents/com~apple~CloudDocs/Project/MinerU"

# 1. 部署测试（最重要）
python tests/deployment/test_full_deployment.py

# 2. 集成测试
python tests/integration/test_mineru.py

# 3. 版本对比测试
python tests/comparison/version_comparison_test.py

# 4. 单元测试（可选）
python -m pytest tests/unittest/
```

## 🐛 故障排除

### 测试失败处理
1. 检查Docker是否运行
2. 确认端口未被占用
3. 验证内存是否充足
4. 查看具体错误日志

### 常见问题
- **超时错误**: 增加测试超时时间
- **端口冲突**: 停止冲突服务或更换端口
- **内存不足**: 关闭其他应用或选择简化版
- **构建失败**: 检查Docker配置和网络连接

## 📈 持续改进

### 测试扩展
- 添加更多PDF样本测试
- 增加性能基准测试
- 扩展错误场景测试
- 添加自动化回归测试

### 监控指标
- 构建成功率
- 测试通过率  
- 性能趋势
- 资源使用趋势

---

💡 **建议**: 在进行任何代码修改后，都应运行完整的测试套件确保系统稳定性。