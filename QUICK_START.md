# MinerU 快速启动指南

🚀 **Apple Silicon Docker 专用版本 - 一键启动指南**

## 📋 系统要求

### 硬件要求
- **处理器**: Apple Silicon (M1/M2/M3/M4) 芯片
- **内存**: 最低8GB (简化版) / 推荐16GB+ (完整版)
- **存储**: 最低10GB可用空间 / 推荐20GB+

### 软件要求
- **操作系统**: macOS (支持Apple Silicon)
- **Docker**: Docker Desktop for Mac (最新版本)

## 🚀 一键启动

### 方法1: 使用启动脚本 (推荐)

```bash
# 进入项目目录
cd "/Users/tieli/Library/Mobile Documents/com~apple~CloudDocs/Project/MinerU"

# 运行启动脚本
./start_mineru_docker.sh
```

### 方法2: 手动选择版本

#### 简化版 (推荐日常使用)
```bash
# 启动简化版 - 端口8000
docker compose -f docker/m1-mac/docker-compose.yml up -d
```

#### 完整版 (推荐专业使用)
```bash
# 启动完整版 - 端口8001
docker compose -f docker/m1-mac-full/docker-compose-fixed.yml up -d
```

## 📊 版本对比

| 特性 | 简化版 | 完整版 |
|------|--------|--------|
| **内存占用** | ~4GB | ~16GB |
| **启动时间** | 快速 | 较慢 |
| **PDF解析** | ✅ | ✅ |
| **OCR识别** | ✅ | ✅ |
| **表格识别** | 基础 | 高级 |
| **公式识别** | ❌ | ✅ (LaTeX) |
| **多模态VLM** | ❌ | ✅ |
| **API端口** | 8000 | 8001 |

## 🌐 访问地址

### 简化版
- **API服务**: http://localhost:8000
- **API文档**: http://localhost:8000/docs
- **健康检查**: http://localhost:8000/health

### 完整版
- **API服务**: http://localhost:8001
- **API文档**: http://localhost:8001/docs
- **健康检查**: http://localhost:8001/health

## 📝 使用示例

### 1. 健康检查
```bash
curl http://localhost:8000/health
curl http://localhost:8001/health
```

### 2. PDF解析
```bash
# 简化版
curl -X POST "http://localhost:8000/file_parse" \
  -F "file=@your_document.pdf" \
  -F "parse_method=auto"

# 完整版
curl -X POST "http://localhost:8001/file_parse" \
  -F "file=@your_document.pdf" \
  -F "parse_method=auto"
```

### 3. Python调用示例
```python
import requests

# 上传PDF文件进行解析
with open('your_document.pdf', 'rb') as f:
    files = {'file': ('document.pdf', f, 'application/pdf')}
    data = {'parse_method': 'auto', 'is_json_md_dump': 'false'}
    
    # 选择版本
    url = "http://localhost:8000/file_parse"  # 简化版
    # url = "http://localhost:8001/file_parse"  # 完整版
    
    response = requests.post(url, files=files, data=data)
    result = response.json()
    print(result['md_content'])
```

## 🛠️ 常用命令

### 查看服务状态
```bash
# 简化版
docker compose -f docker/m1-mac/docker-compose.yml ps

# 完整版
docker compose -f docker/m1-mac-full/docker-compose-fixed.yml ps
```

### 查看日志
```bash
# 简化版
docker compose -f docker/m1-mac/docker-compose.yml logs -f

# 完整版
docker compose -f docker/m1-mac-full/docker-compose-fixed.yml logs -f
```

### 停止服务
```bash
# 简化版
docker compose -f docker/m1-mac/docker-compose.yml down

# 完整版
docker compose -f docker/m1-mac-full/docker-compose-fixed.yml down
```

### 重启服务
```bash
# 简化版
docker compose -f docker/m1-mac/docker-compose.yml restart

# 完整版
docker compose -f docker/m1-mac-full/docker-compose-fixed.yml restart
```

## 🔧 故障排除

### 1. Docker未运行
```bash
# 检查Docker状态
docker info

# 如果失败，请启动Docker Desktop
```

### 2. 端口冲突
```bash
# 检查端口占用
lsof -i :8000
lsof -i :8001

# 如需更换端口，修改对应的docker-compose.yml文件
```

### 3. 内存不足
- 简化版: 确保至少8GB内存
- 完整版: 确保至少16GB内存
- 可通过Activity Monitor查看内存使用情况

### 4. 重新构建镜像
```bash
# 简化版
docker compose -f docker/m1-mac/docker-compose.yml build --no-cache

# 完整版
docker compose -f docker/m1-mac-full/docker-compose-fixed.yml build --no-cache
```

## 🧪 测试验证

### 运行测试脚本
```bash
# 基础功能测试
python test_mineru.py

# 完整部署测试
python test_full_deployment.py

# 版本对比测试
python version_comparison_test.py
```

## 📚 更多信息

- **项目主页**: [GitHub Repository](https://github.com/opendatalab/MinerU)
- **在线演示**: [HuggingFace Demo](https://huggingface.co/spaces/opendatalab/MinerU)
- **API文档**: 启动后访问 `/docs` 端点
- **技术支持**: 查看 `docs/` 目录下的详细文档

## 🤝 获取帮助

如遇问题，请按以下顺序尝试解决：

1. 查看本文档的故障排除部分
2. 检查 `docs/` 目录下的相关文档
3. 运行 `test_full_deployment.py` 进行全面检查
4. 提交Issue到GitHub仓库

---

💡 **提示**: 首次使用建议先选择简化版进行测试，确认功能正常后再考虑使用完整版。