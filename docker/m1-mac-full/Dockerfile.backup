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
    MINERU_MODEL_SOURCE=huggingface \
    DEVICE_MODE=mps \
    ENABLE_VLM=true \
    ENABLE_PIPELINE=true \
    ENABLE_TABLE=true \
    ENABLE_FORMULA=true \
    ENABLE_LLM_AIDED=false \
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
        # 基础工具
        build-essential \
        curl \
        wget \
        git \
        unzip \
        # 图像处理库
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        # OpenCV依赖
        libopencv-dev \
        python3-opencv \
        # 字体支持
        fonts-dejavu-core \
        fontconfig \
        # 网络工具
        ca-certificates \
        # 清理
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
        && fc-cache -fv

# 创建必要目录
RUN mkdir -p /opt/models \
             /opt/layoutreader \
             /app/logs \
             /app/output \
             /app/temp \
             /app/cache \
             /app/config \
             /app/plugins

# 复制requirements文件
COPY requirements-full.txt requirements.txt
COPY constraints.txt constraints.txt

# 设置pip源（支持国内镜像）
RUN pip config set global.index-url https://pypi.org/simple && \
    pip config set global.trusted-host pypi.org

# 安装Python依赖 - 分步安装以优化构建缓存
# 1. 基础依赖
RUN pip install --no-cache-dir -U pip setuptools wheel

# 2. 科学计算库（针对ARM64优化）
RUN pip install --no-cache-dir \
    numpy>=1.24.4 \
    scipy>=1.11.0 \
    pillow>=11.0.0 \
    opencv-python-headless>=4.8.1.78

# 3. PyTorch生态（MPS支持）
RUN pip install --no-cache-dir \
    torch>=2.2.2 \
    torchvision>=0.17.0 \
    torchaudio>=2.2.0 \
    --index-url https://download.pytorch.org/whl/cpu

# 4. 机器学习和深度学习框架
RUN pip install --no-cache-dir \
    transformers>=4.49.0,!=4.51.0,<5.0.0 \
    accelerate>=1.5.1 \
    huggingface-hub>=0.32.4 \
    datasets>=2.14.0

# 5. MinerU完整版安装
RUN pip install --no-cache-dir -c constraints.txt -r requirements.txt

# 复制模型下载脚本
COPY download_models_full.py download_models_full.py
COPY model_config.json model_config.json

# 预下载模型（可选，减少首次启动时间）
ARG PREDOWNLOAD_MODELS=true
RUN if [ "$PREDOWNLOAD_MODELS" = "true" ]; then \
        echo "Pre-downloading models..." && \
        python download_models_full.py --mode=essential; \
    fi

# 复制配置文件
COPY magic-pdf-full.json /root/magic-pdf.json
COPY logging.yml /app/config/logging.yml
COPY model_config.json /app/config/model_config.json

# 复制应用文件
COPY app_full.py app.py
COPY api/ api/
COPY utils/ utils/
COPY plugins/ plugins/
COPY webui/ webui/

# 复制启动脚本
COPY entrypoint.sh entrypoint.sh
COPY healthcheck.sh healthcheck.sh
COPY start.sh start.sh

# 设置执行权限
RUN chmod +x entrypoint.sh healthcheck.sh start.sh && \
    chmod +x download_models_full.py

# 创建非root用户（安全最佳实践）
RUN groupadd -r mineru && \
    useradd -r -g mineru -d /app -s /bin/bash mineru && \
    chown -R mineru:mineru /app /opt/models /opt/layoutreader

# 暴露端口
EXPOSE 8000 3000 8080

# 设置数据卷
VOLUME ["/app/output", "/app/logs", "/app/cache", "/opt/models"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=3 \
    CMD ./healthcheck.sh

# 添加构建时间标签
ARG BUILD_DATE
ARG VERSION
LABEL build_date=$BUILD_DATE
LABEL version=$VERSION

# 切换到非root用户
USER mineru

# 启动命令
ENTRYPOINT ["./entrypoint.sh"]
CMD ["--host", "0.0.0.0", "--port", "8000", "--workers", "4"]