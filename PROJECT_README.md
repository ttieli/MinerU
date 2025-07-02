# MinerU - Apple Silicon Docker 专用版

🚀 **高性能PDF文档解析工具 - 为Apple Silicon优化的Docker版本**

[![Docker](https://img.shields.io/badge/Docker-Optimized-blue.svg)](https://www.docker.com/)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3%2FM4-green.svg)](https://support.apple.com/en-us/HT211814)
[![Python](https://img.shields.io/badge/Python-3.9%2B-blue.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](https://opensource.org/licenses/Apache-2.0)

## 🎯 项目特色

### ✨ 专为Apple Silicon优化
- **原生支持**: M1/M2/M3/M4芯片原生优化
- **双版本选择**: 简化版(8GB) + 完整版(16GB+)
- **智能推荐**: 根据系统资源自动推荐版本
- **一键部署**: 全自动化启动脚本

### 🔧 核心功能
- **PDF解析**: 高精度PDF文档结构解析
- **OCR识别**: 多语言光学字符识别
- **表格提取**: 智能表格结构识别
- **公式识别**: LaTeX数学公式提取（完整版）
- **多模态VLM**: 视觉语言模型支持（完整版）

## 🚀 快速开始

### 📋 系统要求
- **硬件**: Apple Silicon (M1/M2/M3/M4)
- **系统**: macOS 
- **内存**: 8GB (简化版) / 16GB+ (完整版)
- **软件**: Docker Desktop for Mac

### ⚡ 一键启动
```bash
# 克隆仓库
git clone https://github.com/opendatalab/MinerU.git
cd MinerU

# 一键启动（自动选择版本）
./start_mineru_docker.sh
```

### 🎯 版本选择

#### 🟢 简化版 (推荐日常使用)
```bash
# 端口8000，内存占用4GB
docker compose -f docker/m1-mac/docker-compose.yml up -d
```

#### 🔵 完整版 (推荐专业使用)  
```bash
# 端口8001，内存占用16GB
docker compose -f docker/m1-mac-full/docker-compose-fixed.yml up -d
```

## 📊 版本对比

| 特性 | 简化版 | 完整版 |
|------|--------|--------|
| **内存需求** | 8GB | 16GB+ |
| **启动时间** | 快速 | 较慢 |
| **PDF解析** | ✅ | ✅ |
| **OCR识别** | ✅ | ✅ (增强) |
| **表格识别** | 基础 | 高级 |
| **公式识别** | ❌ | ✅ LaTeX |
| **多模态VLM** | ❌ | ✅ |
| **API端口** | 8000 | 8001 |
| **适用场景** | 日常文档处理 | 专业文档分析 |

## 🌐 使用示例

### API调用
```python
import requests

# 上传PDF进行解析
with open('document.pdf', 'rb') as f:
    files = {'file': ('doc.pdf', f, 'application/pdf')}
    data = {'parse_method': 'auto'}
    
    # 简化版
    response = requests.post('http://localhost:8000/file_parse', 
                           files=files, data=data)
    
    # 完整版  
    response = requests.post('http://localhost:8001/file_parse',
                           files=files, data=data)
    
    result = response.json()
    print(result['md_content'])
```

### 命令行调用
```bash
# 健康检查
curl http://localhost:8000/health
curl http://localhost:8001/health

# PDF解析
curl -X POST "http://localhost:8000/file_parse" \
  -F "file=@document.pdf" \
  -F "parse_method=auto"
```

## 🔧 管理命令

```bash
# 查看状态
docker compose -f docker/m1-mac/docker-compose.yml ps

# 查看日志
docker compose -f docker/m1-mac/docker-compose.yml logs -f

# 停止服务
docker compose -f docker/m1-mac/docker-compose.yml down

# 重启服务
docker compose -f docker/m1-mac/docker-compose.yml restart
```

## 🧪 测试验证

```bash
# 基础功能测试
python tests/integration/test_mineru.py

# 完整部署测试
python tests/deployment/test_full_deployment.py

# 版本对比测试
python tests/comparison/version_comparison_test.py
```

## 📚 项目结构

```
MinerU/
├── 🚀 QUICK_START.md              # 快速启动指南
├── ⚙️ start_mineru_docker.sh      # 一键启动脚本
├── 🐳 docker/                     # Docker配置
│   ├── m1-mac/                    # 简化版配置
│   └── m1-mac-full/               # 完整版配置
├── 🧪 tests/                      # 测试套件
│   ├── integration/               # 集成测试
│   ├── deployment/                # 部署测试
│   └── comparison/                # 版本对比
├── 📚 docs/                       # 项目文档
├── 🐍 mineru/                     # 核心Python包
└── 🚀 projects/                   # 子项目应用
```

## 🎨 功能演示

### 简化版特点
- ⚡ 快速启动 (30-60秒)
- 💾 内存友好 (4GB)
- 📄 基础PDF解析
- 🔤 OCR文字识别
- 📊 基础表格提取

### 完整版增强
- 🧠 VLM多模态理解
- 🔬 高精度表格识别
- ⚗️ LaTeX公式提取
- 🎯 智能布局分析
- 📈 专业文档处理

## 🛠️ 故障排除

### 常见问题
1. **Docker未运行**: 启动Docker Desktop
2. **端口冲突**: 检查8000/8001端口占用
3. **内存不足**: 选择简化版或释放内存
4. **构建失败**: 检查网络连接和Docker配置

### 获取帮助
- 📖 查看 [QUICK_START.md](QUICK_START.md)
- 🔍 查看 [docs/](docs/) 目录文档
- 🧪 运行 `test_full_deployment.py` 诊断
- 🐛 提交Issue到GitHub

## 📈 性能指标

### 测试结果 (Apple M2 Pro 16GB)
- **简化版**: 7.14秒处理，5,552字符输出
- **完整版**: 66.38秒处理，6,711字符输出
- **内容增强**: 21%更多内容
- **公式识别**: 76个LaTeX公式 vs 0个

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 推送分支
5. 创建Pull Request

## 📄 许可证

本项目采用 Apache 2.0 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- 感谢 [OpenDataLab](https://github.com/opendatalab) 的原始MinerU项目
- 感谢Apple Silicon优化和Docker封装工作
- 感谢所有贡献者和测试用户的反馈

---

🌟 **如果这个项目对您有帮助，请给个Star！** ⭐

📞 **技术支持**: 遇到问题请查看文档或提交Issue