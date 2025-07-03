import json
import os
import gc
import asyncio
import multiprocessing
from base64 import b64encode
from glob import glob
from io import StringIO
import tempfile
from typing import Tuple
from concurrent.futures import ThreadPoolExecutor

import uvicorn
from fastapi import FastAPI, HTTPException, UploadFile, Form
from fastapi.responses import JSONResponse
from loguru import logger

# MinerU imports
from mineru.data.data_reader_writer import DataWriter, FileBasedDataWriter
from mineru.data.data_reader_writer.s3 import S3DataReader, S3DataWriter
from mineru.utils.config_reader import get_device
from mineru.backend.pipeline.model_init import MineruPipelineModel

# 全局模型变量
model: MineruPipelineModel = None

# 异步配置
CPU_COUNT = multiprocessing.cpu_count()
THREAD_POOL_SIZE = min(CPU_COUNT * 2, 6)  # 限制线程池大小适应M1芯片
executor = ThreadPoolExecutor(max_workers=THREAD_POOL_SIZE)

# 初始化FastAPI应用
app = FastAPI(
    title="MinerU API - M1 Mac Optimized (Async)",
    description="PDF解析API服务 - 针对M1芯片Mac优化 + 异步并发处理",
    version="1.1.0-async"
)

# 文件扩展名定义
pdf_extensions = [".pdf"]
office_extensions = [".ppt", ".pptx", ".doc", ".docx"]
image_extensions = [".png", ".jpg", ".jpeg"]

@app.on_event("startup")
async def startup_event():
    """在服务启动时预加载模型"""
    global model
    logger.info("开始预加载MinerU模型...")
    device = get_device()
    
    try:
        # 使用简化配置加载，启用核心功能
        model = MineruPipelineModel(
            device=device, 
            table_config={"enable": True}, 
            formula_config={"enable": False}  # 暂时禁用公式以加快初始化
        )
        logger.info("MinerU模型预加载完成，服务就绪。")
    except Exception as e:
        logger.error(f"模型加载失败: {e}")
        # 设置为None，将在第一次请求时延迟加载
        model = None

class MemoryDataWriter(DataWriter):
    """内存数据写入器，避免频繁文件IO"""
    def __init__(self):
        self.buffer = StringIO()

    def write(self, path: str, data: bytes) -> None:
        if isinstance(data, str):
            self.buffer.write(data)
        else:
            self.buffer.write(data.decode("utf-8"))

    def write_string(self, path: str, data: str) -> None:
        self.buffer.write(data)

    def get_value(self) -> str:
        return self.buffer.getvalue()

    def close(self):
        self.buffer.close()

def cleanup_memory():
    """清理内存"""
    gc.collect()

def init_writers(
    file_path: str = None,
    file: UploadFile = None,
    output_path: str = None,
    output_image_path: str = None,
) -> Tuple[
    FileBasedDataWriter,
    FileBasedDataWriter,
    bytes,
    str
]:
    """初始化写入器"""
    file_extension = None
    if file_path:
        is_s3_path = file_path.startswith("s3://")
        if is_s3_path:
            # S3路径处理（简化版暂不支持）
            raise ValueError("S3路径暂不支持")
        else:
            writer = FileBasedDataWriter(output_path)
            image_writer = FileBasedDataWriter(output_image_path)
            os.makedirs(output_image_path, exist_ok=True)
            with open(file_path, "rb") as f:
                file_bytes = f.read()
            file_extension = os.path.splitext(file_path)[1]
    else:
        file_bytes = file.file.read()
        file_extension = os.path.splitext(file.filename)[1]

        writer = FileBasedDataWriter(output_path)
        image_writer = FileBasedDataWriter(output_image_path)
        os.makedirs(output_image_path, exist_ok=True)

    return writer, image_writer, file_bytes, file_extension

def encode_image(image_path: str) -> str:
    """Base64编码图像"""
    with open(image_path, "rb") as f:
        return b64encode(f.read()).decode()

def process_file_sync(file_bytes: bytes, file_name: str, writer, image_writer, model_instance):
    """同步文件处理函数 - 用于在线程池中执行"""
    import time
    start_time = time.time()
    
    result, md_content = model_instance.predict(
        b_content=file_bytes,
        file_name=file_name,
        writer=writer,
        image_writer=image_writer,
    )
    
    processing_time = time.time() - start_time
    logger.info(f"文件解析完成，耗时: {processing_time:.2f}秒")
    
    return result, md_content

@app.get("/", tags=["root"])
async def root():
    """根路径"""
    return {"message": "MinerU API - M1 Mac Optimized", "status": "running"}

@app.get("/health", tags=["health"])
async def health_check():
    """健康检查"""
    return {"status": "healthy", "service": "mineru-m1-async", "version": "1.1.0-async"}

@app.get("/status", tags=["monitoring"])
async def get_async_status():
    """获取异步处理状态"""
    active_threads = len(executor._threads) if hasattr(executor, '_threads') else 0
    queue_size = executor._work_queue.qsize() if hasattr(executor, '_work_queue') and hasattr(executor._work_queue, 'qsize') else 0
    
    return {
        "thread_pool_size": THREAD_POOL_SIZE,
        "active_threads": active_threads,
        "queue_size": queue_size,
        "cpu_count": CPU_COUNT,
        "model_loaded": model is not None
    }

@app.post("/file_parse", tags=["parse"], summary="解析文件 (PDF/Office/图像)")
async def file_parse(
    file: UploadFile = None,
    file_path: str = Form(None),
    parse_method: str = Form("auto"),
    is_json_md_dump: bool = Form(False),
    output_dir: str = Form("output"),
    return_layout: bool = Form(False),
    return_info: bool = Form(False),
    return_content_list: bool = Form(False),
    return_images: bool = Form(False),
):
    """
    解析PDF/Office/图像文件为JSON和Markdown格式
    
    参数:
        file: 要解析的文件 (与file_path二选一)
        file_path: 文件路径 (与file二选一)
        parse_method: 解析方法 auto/ocr/txt，默认auto
        is_json_md_dump: 是否保存解析结果到文件，默认False
        output_dir: 输出目录，默认output
        return_layout: 是否返回布局信息，默认False
        return_info: 是否返回文档信息，默认False
        return_content_list: 是否返回内容列表，默认False
        return_images: 是否返回图像，默认False
    """
    try:
        # 参数验证
        if (file is None and file_path is None) or (file is not None and file_path is not None):
            return JSONResponse(
                content={"error": "必须提供file或file_path其中之一"},
                status_code=400,
            )

        # 获取文件名
        file_name = os.path.basename(file_path if file_path else file.filename).split(".")[0]
        output_path = f"{output_dir}/{file_name}"
        output_image_path = f"{output_path}/images"

        # 增加日志以进行调试
        logger.info(f"文件名 (file_name): {file_name}")
        logger.info(f"输出目录 (output_dir): {output_dir}")
        logger.info(f"最终输出路径 (output_path): {output_path}")

        # 初始化写入器和获取文件内容
        writer, image_writer, file_bytes, file_extension = init_writers(
            file_path=file_path,
            file=file,
            output_path=output_path,
            output_image_path=output_image_path,
        )

        # 确保模型已加载
        global model
        if model is None:
            logger.info("模型未加载，正在延迟初始化...")
            device = get_device()
            model = MineruPipelineModel(
                device=device, 
                table_config={"enable": True}, 
                formula_config={"enable": False}
            )
            logger.info("延迟模型加载完成")
        
        # 异步调用核心解析逻辑
        logger.info(f"开始异步解析文件: {file_name} (线程池大小: {THREAD_POOL_SIZE})")
        
        # 使用线程池执行CPU密集型任务
        loop = asyncio.get_event_loop()
        result, md_content = await loop.run_in_executor(
            executor,
            process_file_sync,
            file_bytes, file_name, writer, image_writer, model
        )

        # 构建返回数据
        data = {
            "result": result,
            "md_content": md_content
        }
        
        # 兼容旧的返回参数（简化处理）
        if return_layout:
            data["layout"] = result.get("layout", {})
        if return_info:
            data["info"] = {"filename": file_name, "type": file_extension}
        if return_content_list:
            data["content_list"] = result.get("content_list", [])
        if return_images:
            image_paths = glob(f"{output_image_path}/*.png")
            data["images"] = {os.path.basename(p): encode_image(p) for p in image_paths}

        # === 产物写入逻辑 ===
        if is_json_md_dump:
            logger.info(f"--- 开始写入产物 ---")
            logger.info(f"目标路径: {output_path}")
            try:
                os.makedirs(output_path, exist_ok=True)
                logger.info(f"目录检查/创建成功: {output_path}")

                writer.write_string(os.path.join(output_path, "content.md"), data["md_content"])
                logger.info(f"写入 content.md 成功")

                writer.write_string(os.path.join(output_path, "result.json"), json.dumps(result, ensure_ascii=False, indent=2))
                logger.info(f"写入 result.json 成功")
                
            except Exception as e:
                logger.error(f"!!!!!! 写入产物时发生严重错误: {e} !!!!!!")
            logger.info(f"--- 结束写入产物 ---")

        cleanup_memory()
        return JSONResponse(data, status_code=200)

    except Exception as e:
        logger.exception(e)
        cleanup_memory()
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.on_event("shutdown")
async def shutdown_event():
    """服务关闭时的清理工作"""
    logger.info("正在关闭服务，清理线程池...")
    executor.shutdown(wait=True)
    logger.info("线程池清理完成")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)