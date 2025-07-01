import json
import os
import gc
from base64 import b64encode
from glob import glob
from io import StringIO
import tempfile
from typing import Tuple

import uvicorn
from fastapi import FastAPI, HTTPException, UploadFile, Form
from fastapi.responses import JSONResponse
from loguru import logger

# MinerU imports - 更新为正确的导入路径
from mineru.data.data_reader_writer import DataWriter, FileBasedDataWriter
from mineru.data.data_reader_writer.s3 import S3DataReader, S3DataWriter
from mineru.utils.config_reader import get_device
from mineru.backend.pipeline.pipeline_analyze import doc_analyze

# 初始化FastAPI应用
app = FastAPI(
    title="MinerU API - M1 Mac Optimized",
    description="PDF解析API服务 - 针对M1芯片Mac优化",
    version="1.0.0"
)

# 文件扩展名定义
pdf_extensions = [".pdf"]
office_extensions = [".ppt", ".pptx", ".doc", ".docx"]
image_extensions = [".png", ".jpg", ".jpeg"]

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

def process_file(
    file_bytes: bytes,
    file_extension: str,
    parse_method: str,
    output_path: str,
) -> dict:
    """处理文件内容 - 简化版实现"""
    
    # 创建临时文件
    temp_dir = tempfile.mkdtemp()
    temp_file_path = os.path.join(temp_dir, f"temp_file{file_extension}")
    
    try:
        with open(temp_file_path, "wb") as f:
            f.write(file_bytes)
        
        # 简化版：直接返回基本信息
        result = {
            "filename": os.path.basename(temp_file_path),
            "size": len(file_bytes),
            "type": file_extension,
            "method": parse_method,
            "status": "processed"
        }
        
        return result
    
    finally:
        # 清理临时文件
        import shutil
        shutil.rmtree(temp_dir, ignore_errors=True)
        cleanup_memory()

def encode_image(image_path: str) -> str:
    """Base64编码图像"""
    with open(image_path, "rb") as f:
        return b64encode(f.read()).decode()

@app.get("/", tags=["root"])
async def root():
    """根路径"""
    return {"message": "MinerU API - M1 Mac Optimized", "status": "running"}

@app.get("/health", tags=["health"])
async def health_check():
    """健康检查"""
    return {"status": "healthy", "service": "mineru-m1"}

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
    解析PDF/Office/图像文件为JSON和Markdown格式 - 简化版实现
    
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

        # 初始化写入器和获取文件内容
        writer, image_writer, file_bytes, file_extension = init_writers(
            file_path=file_path,
            file=file,
            output_path=output_path,
            output_image_path=output_image_path,
        )

        # 处理文件 - 简化版实现
        result = process_file(file_bytes, file_extension, parse_method, output_path)

        # 构建返回数据
        data = {
            "result": result,
            "md_content": f"# {file_name}\n\n处理完成 - 简化版实现\n\n文件类型: {file_extension}\n解析方法: {parse_method}"
        }
        
        if return_layout:
            data["layout"] = {"status": "简化版暂不支持layout返回"}
        if return_info:
            data["info"] = {"filename": file_name, "type": file_extension}
        if return_content_list:
            data["content_list"] = [{"type": "text", "content": f"文件 {file_name} 处理完成"}]
        if return_images:
            data["images"] = {}

        cleanup_memory()
        return JSONResponse(data, status_code=200)

    except Exception as e:
        logger.exception(e)
        cleanup_memory()
        return JSONResponse(content={"error": str(e)}, status_code=500)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)