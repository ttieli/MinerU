import json
import os
import gc
from base64 import b64encode
from glob import glob
from io import StringIO
import tempfile
from typing import Tuple, Union

import uvicorn
from fastapi import FastAPI, HTTPException, UploadFile, Form
from fastapi.responses import JSONResponse
from loguru import logger

# MinerU imports
from magic_pdf.data.read_api import read_local_images, read_local_office
import magic_pdf.model as model_config
from magic_pdf.config.enums import SupportedPdfParseMethod
from magic_pdf.data.data_reader_writer import DataWriter, FileBasedDataWriter
from magic_pdf.data.data_reader_writer.s3 import S3DataReader, S3DataWriter
from magic_pdf.data.dataset import ImageDataset, PymuDocDataset
from magic_pdf.libs.config_reader import get_bucket_name, get_s3_config
from magic_pdf.model.doc_analyze_by_custom_model import doc_analyze
from magic_pdf.operators.models import InferenceResult
from magic_pdf.operators.pipes import PipeResult

# 启用内部模型模式
model_config.__use_inside_model__ = True

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
    Union[S3DataWriter, FileBasedDataWriter],
    Union[S3DataWriter, FileBasedDataWriter],
    bytes,
    str
]:
    """初始化写入器"""
    file_extension = None
    if file_path:
        is_s3_path = file_path.startswith("s3://")
        if is_s3_path:
            bucket = get_bucket_name(file_path)
            ak, sk, endpoint = get_s3_config(bucket)

            writer = S3DataWriter(
                output_path, bucket=bucket, ak=ak, sk=sk, endpoint_url=endpoint
            )
            image_writer = S3DataWriter(
                output_image_path, bucket=bucket, ak=ak, sk=sk, endpoint_url=endpoint
            )
            temp_reader = S3DataReader(
                "", bucket=bucket, ak=ak, sk=sk, endpoint_url=endpoint
            )
            file_bytes = temp_reader.read(file_path)
            file_extension = os.path.splitext(file_path)[1]
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
    image_writer: Union[S3DataWriter, FileBasedDataWriter],
) -> Tuple[InferenceResult, PipeResult]:
    """处理文件内容"""
    ds: Union[PymuDocDataset, ImageDataset] = None
    
    try:
        if file_extension in pdf_extensions:
            ds = PymuDocDataset(file_bytes)
        elif file_extension in office_extensions:
            temp_dir = tempfile.mkdtemp()
            temp_file_path = os.path.join(temp_dir, f"temp_file{file_extension}")
            with open(temp_file_path, "wb") as f:
                f.write(file_bytes)
            ds = read_local_office(temp_dir)[0]
        elif file_extension in image_extensions:
            temp_dir = tempfile.mkdtemp()
            temp_file_path = os.path.join(temp_dir, f"temp_file{file_extension}")
            with open(temp_file_path, "wb") as f:
                f.write(file_bytes)
            ds = read_local_images(temp_dir)[0]
        else:
            raise ValueError(f"不支持的文件类型: {file_extension}")

        infer_result: InferenceResult = None
        pipe_result: PipeResult = None

        if parse_method == "ocr":
            infer_result = ds.apply(doc_analyze, ocr=True)
            pipe_result = infer_result.pipe_ocr_mode(image_writer)
        elif parse_method == "txt":
            infer_result = ds.apply(doc_analyze, ocr=False)
            pipe_result = infer_result.pipe_txt_mode(image_writer)
        else:  # auto
            if ds.classify() == SupportedPdfParseMethod.OCR:
                infer_result = ds.apply(doc_analyze, ocr=True)
                pipe_result = infer_result.pipe_ocr_mode(image_writer)
            else:
                infer_result = ds.apply(doc_analyze, ocr=False)
                pipe_result = infer_result.pipe_txt_mode(image_writer)

        return infer_result, pipe_result
    
    finally:
        # 清理临时文件
        if 'temp_dir' in locals():
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

        # 初始化写入器和获取文件内容
        writer, image_writer, file_bytes, file_extension = init_writers(
            file_path=file_path,
            file=file,
            output_path=output_path,
            output_image_path=output_image_path,
        )

        # 处理文件
        infer_result, pipe_result = process_file(file_bytes, file_extension, parse_method, image_writer)

        # 使用内存写入器获取结果
        content_list_writer = MemoryDataWriter()
        md_content_writer = MemoryDataWriter()
        middle_json_writer = MemoryDataWriter()

        try:
            # 使用PipeResult的dump方法获取数据
            pipe_result.dump_content_list(content_list_writer, "", "images")
            pipe_result.dump_md(md_content_writer, "", "images")
            pipe_result.dump_middle_json(middle_json_writer, "")

            # 获取内容
            content_list = json.loads(content_list_writer.get_value())
            md_content = md_content_writer.get_value()
            middle_json = json.loads(middle_json_writer.get_value())
            model_json = infer_result.get_infer_res()

            # 如果需要保存结果
            if is_json_md_dump:
                writer.write_string(f"{file_name}_content_list.json", content_list_writer.get_value())
                writer.write_string(f"{file_name}.md", md_content)
                writer.write_string(f"{file_name}_middle.json", middle_json_writer.get_value())
                writer.write_string(
                    f"{file_name}_model.json",
                    json.dumps(model_json, indent=4, ensure_ascii=False),
                )

            # 构建返回数据
            data = {}
            if return_layout:
                data["layout"] = model_json
            if return_info:
                data["info"] = middle_json
            if return_content_list:
                data["content_list"] = content_list
            if return_images:
                image_paths = glob(f"{output_image_path}/*.jpg")
                data["images"] = {
                    os.path.basename(image_path): f"data:image/jpeg;base64,{encode_image(image_path)}"
                    for image_path in image_paths[:5]  # 限制图像数量以节省内存
                }
            
            data["md_content"] = md_content  # 总是返回MD内容

        finally:
            # 清理内存写入器
            content_list_writer.close()
            md_content_writer.close()
            middle_json_writer.close()
            cleanup_memory()

        return JSONResponse(data, status_code=200)

    except Exception as e:
        logger.exception(e)
        cleanup_memory()
        return JSONResponse(content={"error": str(e)}, status_code=500)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)