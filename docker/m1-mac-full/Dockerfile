# MinerU M芯片全功能版 Dockerfile
# 基于Python 3.11镜像，为Apple Silicon优化
FROM python:3.11-slim

# 维护者信息
LABEL maintainer="MinerU Team <support@mineru.net>"
LABEL description="MinerU Full-Featured Docker Image for Apple Silicon"
LABEL version="2.0-full"

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    DEVICE_MODE=mps \
    ENABLE_VLM=true \
    ENABLE_PIPELINE=true \
    ENABLE_TABLE=true \
    ENABLE_FORMULA=true \
    MAX_WORKERS=4 \
    BATCH_SIZE=2 \
    MEMORY_LIMIT=8G \
    MODEL_PRECISION=fp16 \
    PYTORCH_ENABLE_MPS_FALLBACK=1 \
    PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0 \
    MPS_MEMORY_FRACTION=0.8

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        wget \
        git \
        unzip \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        libopencv-dev \
        python3-opencv \
        fonts-dejavu-core \
        fontconfig \
        ca-certificates \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
        && fc-cache -fv

# 创建必要目录
RUN mkdir -p /app/logs \
             /app/output \
             /app/temp \
             /app/cache

# 复制requirements文件
COPY requirements-full.txt requirements.txt

# 如果存在constraints文件则复制
COPY constraints.txt* ./

# 安装Python依赖
RUN pip install --no-cache-dir -U pip setuptools wheel

# 基础科学计算库
RUN pip install --no-cache-dir \
    numpy>=1.24.4 \
    scipy>=1.11.0 \
    pillow>=11.0.0 \
    opencv-python-headless>=4.8.1.78

# PyTorch生态（MPS支持）
RUN pip install --no-cache-dir \
    torch>=2.2.2 \
    torchvision>=0.17.0 \
    torchaudio>=2.2.0 \
    --index-url https://download.pytorch.org/whl/cpu

# 机器学习框架
RUN pip install --no-cache-dir \
    transformers>=4.49.0 \
    accelerate>=1.5.1 \
    huggingface-hub>=0.32.4

# 安装其他依赖
RUN if [ -f constraints.txt ]; then \
        pip install --no-cache-dir -c constraints.txt -r requirements.txt; \
    else \
        pip install --no-cache-dir -r requirements.txt; \
    fi

# 复制应用文件
COPY app_full.py app.py

# 复制配置文件（如果存在）
COPY magic-pdf-full.json* /root/

# 复制启动脚本
COPY entrypoint.sh* ./
COPY healthcheck.sh* ./

# 如果没有entrypoint.sh，创建一个简单的
RUN if [ ! -f entrypoint.sh ]; then \
        echo '#!/bin/bash' > entrypoint.sh && \
        echo 'exec python app.py "$@"' >> entrypoint.sh; \
    fi

# 如果没有healthcheck.sh，创建一个简单的
RUN if [ ! -f healthcheck.sh ]; then \
        echo '#!/bin/bash' > healthcheck.sh && \
        echo 'curl -f http://localhost:8000/health || exit 1' >> healthcheck.sh; \
    fi

# 设置执行权限
RUN chmod +x entrypoint.sh healthcheck.sh

# 创建非root用户
RUN groupadd -r mineru && \
    useradd -r -g mineru -d /app -s /bin/bash mineru && \
    chown -R mineru:mineru /app

# 暴露端口
EXPOSE 8000

# 设置数据卷
VOLUME ["/app/output", "/app/logs", "/app/cache"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=3 \
    CMD ./healthcheck.sh

# 切换到非root用户
USER mineru

# 启动命令
ENTRYPOINT ["./entrypoint.sh"]
CMD ["--host", "0.0.0.0", "--port", "8000"]