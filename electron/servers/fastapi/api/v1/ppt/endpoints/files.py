import os
from typing import Annotated, List, Optional
from fastapi import APIRouter, Body, File, HTTPException, UploadFile
from fastapi.responses import FileResponse

from constants.documents import UPLOAD_ACCEPTED_FILE_TYPES
from models.decompose_files_body import DecomposeFilesBody
from models.decomposed_file_info import DecomposedFileInfo
from services.temp_file_service import TEMP_FILE_SERVICE
from services.documents_loader import DocumentsLoader
import uuid
from utils.validators import validate_files

FILES_ROUTER = APIRouter(prefix="/files", tags=["Files"])


@FILES_ROUTER.post("/upload", response_model=List[str])
async def upload_files(files: Optional[List[UploadFile]]):
    if not files:
        raise HTTPException(400, "Documents are required")

    temp_dir = TEMP_FILE_SERVICE.create_temp_dir(str(uuid.uuid4()))

    validate_files(files, True, True, 100, UPLOAD_ACCEPTED_FILE_TYPES)

    temp_files: List[str] = []
    if files:
        for each_file in files:
            temp_path = TEMP_FILE_SERVICE.create_temp_file_path(
                each_file.filename, temp_dir
            )
            with open(temp_path, "wb") as f:
                content = await each_file.read()
                f.write(content)

            temp_files.append(temp_path)

    return temp_files


@FILES_ROUTER.post("/decompose", response_model=List[DecomposedFileInfo])
async def decompose_files(body: DecomposeFilesBody):
    temp_dir = TEMP_FILE_SERVICE.create_temp_dir(str(uuid.uuid4()))

    txt_files = []
    other_files = []
    for file_path in body.file_paths:
        if file_path.endswith(".txt"):
            txt_files.append(file_path)
        else:
            other_files.append(file_path)

    documents_loader = DocumentsLoader(
        file_paths=other_files,
        presentation_language=body.language,
    )
    await documents_loader.load_documents(temp_dir)
    parsed_documents = documents_loader.documents

    response = []
    for index, parsed_doc in enumerate(parsed_documents):
        file_path = TEMP_FILE_SERVICE.create_temp_file_path(
            f"{uuid.uuid4()}.txt", temp_dir
        )
        parsed_doc = parsed_doc.replace("<br>", "\n")
        with open(file_path, "w", encoding="utf-8") as text_file:
            text_file.write(parsed_doc)
        response.append(
            DecomposedFileInfo(
                name=os.path.basename(other_files[index]), file_path=file_path
            )
        )

    # Return the txt documents as it is
    for each_file in txt_files:
        response.append(
            DecomposedFileInfo(name=os.path.basename(each_file), file_path=each_file)
        )

    return response


@FILES_ROUTER.post("/update")
async def update_files(
    file_path: Annotated[str, Body()],
    file: Annotated[UploadFile, File()],
):
    with open(file_path, "wb") as f:
        f.write(await file.read())

    return {"message": "File updated successfully"}


@FILES_ROUTER.get("/download")
async def download_file(path: str):
    """Serve an exported file for download. Path must be under /app_data/exports/."""
    app_data = os.environ.get("APP_DATA_DIRECTORY", "/app_data")
    exports_dir = os.path.realpath(os.path.join(app_data, "exports"))

    # Only allow paths under /app_data/exports/
    if not path.startswith("/app_data/exports/"):
        raise HTTPException(status_code=403, detail="Access denied: path not in exports directory")

    relative = path[len("/app_data/exports/"):]
    # Reject traversal attempts before resolving
    if ".." in relative:
        raise HTTPException(status_code=403, detail="Access denied: invalid path")

    file_path = os.path.realpath(os.path.join(exports_dir, relative))

    # Ensure resolved path stays inside exports dir
    if not file_path.startswith(exports_dir + os.sep) and file_path != exports_dir:
        raise HTTPException(status_code=403, detail="Access denied: path outside exports directory")

    if not os.path.isfile(file_path):
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(file_path, filename=os.path.basename(file_path))
