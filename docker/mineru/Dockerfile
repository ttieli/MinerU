# MinerU Docker统一镜像构建文件
# 支持Simple和Full两种版本的动态配置

# ========== 基础镜像阶段 ==========
FROM python:3.10-slim as base

# 设置构建参数
ARG VERSION=simple
ARG BUILD_DATE
ARG PYTHON_VERSION=3.10

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    MINERU_VERSION=${VERSION}

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libreoffice \
    poppler-utils \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ========== 依赖安装阶段 ==========
FROM base as dependencies

# 复制项目文件
COPY . /app/

# 根据版本选择requirements文件
RUN if [ "$VERSION" = "full" ]; then \
        echo "安装完整版依赖..." && \
        pip install -r docker/m1-mac-full/requirements-full.txt; \
    else \
        echo "安装简化版依赖..." && \
        pip install -r docker/m1-mac/requirements.txt; \
    fi

# 安装MinerU核心包
RUN pip install -e .

# ========== 模型下载阶段 ==========
FROM dependencies as models

# 创建模型目录
RUN mkdir -p /opt/models /opt/layoutreader

# 根据版本下载不同的模型
RUN if [ "$VERSION" = "full" ]; then \
        echo "下载完整版模型..." && \
        python docker/m1-mac-full/download_models_full.py; \
    else \
        echo "下载简化版模型..." && \
        python docker/m1-mac/download_models_light.py; \
    fi

# ========== 应用配置阶段 ==========
FROM models as app

# 复制应用文件
RUN if [ "$VERSION" = "full" ]; then \
        cp docker/m1-mac-full/app_full.py app.py && \
        cp docker/m1-mac-full/magic-pdf-full.json magic-pdf.json; \
    else \
        cp docker/m1-mac/app.py app.py && \
        cp docker/m1-mac/magic-pdf-m1.json magic-pdf.json; \
    fi

# 复制健康检查脚本
COPY docker/mineru/healthcheck.sh /app/healthcheck.sh
RUN chmod +x /app/healthcheck.sh

# 复制启动脚本
COPY docker/mineru/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# 创建必要的目录
RUN mkdir -p \
    /app/output \
    /app/temp \
    /app/cache \
    /app/logs \
    /app/config

# 设置权限
RUN chown -R 1000:1000 /app /opt/models /opt/layoutreader

# 切换到非root用户
USER 1000

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /app/healthcheck.sh

# 设置启动命令
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]

# 添加标签
LABEL maintainer="MinerU Team" \
      version="${VERSION}" \
      build-date="${BUILD_DATE}" \
      description="MinerU PDF解析服务 - ${VERSION}版本" \
      org.opencontainers.image.title="MinerU" \
      org.opencontainers.image.description="高性能PDF解析和文档处理服务" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}"