FROM python:3.10-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    MINERU_MODEL_SOURCE=huggingface

# 安装系统依赖 (仅安装必需的包以减少内存占用)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libgl1 \
        libglib2.0-0 \
        libgomp1 \
        curl \
        wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 复制requirements文件
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 创建模型目录
RUN mkdir -p /opt/models /opt/layoutreader

# 复制模型下载脚本并执行 (只下载核心模型以节省空间)
COPY download_models_light.py .
RUN python download_models_light.py

# 复制应用文件
COPY app.py .
COPY magic-pdf-m1.json /root/magic-pdf.json
COPY entrypoint.sh .

# 设置执行权限
RUN chmod +x entrypoint.sh

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 启动命令
ENTRYPOINT ["./entrypoint.sh"]
CMD ["--host", "0.0.0.0", "--port", "8000"]