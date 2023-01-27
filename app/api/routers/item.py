import io
from functools import lru_cache
from typing import List

import boto3
from sqlalchemy.orm import Session
from fastapi import Depends, APIRouter, HTTPException, Form, File, UploadFile
from fastapi.responses import FileResponse, StreamingResponse

from api import session
from api.lib import auth
from api.env import get_env
from api.lib.utils import Utils
from api.lib.logger import logger, logging_error_exception, logging_warn_exception
from api.models import User, ItemDataFormat
from api.crud import item as crud_item
from api.schemas.item import ItemSchema, ItemSchemaWithoutContent


@lru_cache
def get_s3_client(_ttl_hash: int = Depends(Utils.get_ttl_hash)):
    print(f"get_s3_client _ttl_hash: {_ttl_hash}")
    return boto3.client("s3", region_name=get_env().aws_region)

def s3_client_factory():
    return get_s3_client(Utils.get_ttl_hash(1800))

router = APIRouter()

@router.post("/items/", response_model=ItemSchema)
async def create(
    # request form and files: https://fastapi.tiangolo.com/tutorial/request-forms-and-files/
    name: str = Form(...),
    file: UploadFile = File(...),
    is_common: bool = Form(...),
    data_format: ItemDataFormat = Form(...),
    _s3_client = Depends(s3_client_factory),
    session: Session = Depends(session.get_session),
    current_user: User = Depends(auth.get_current_active_user)
):
    content = await file.read()
    try:
        item = crud_item.create(
            session,
            name=name,
            content=content.decode("utf-8"),
            is_common=is_common,
            data_format=data_format,
            user=current_user
        )
    except Exception as e:
        logging_error_exception(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")

    return item


@router.get("/items/", response_model=List[ItemSchemaWithoutContent])
def get_list(
    skip: int = 0,
    limit: int = 100,
    session: Session = Depends(session.get_session),
    current_user: User = Depends(auth.get_current_active_user)
):
    return crud_item.get_list_include_common(session, current_user.id, skip, limit)


@router.get("/items/{item_id}", response_model=ItemSchema)
def get(
    item_id: int,
    session: Session = Depends(session.get_session),
    current_user: User = Depends(auth.get_current_active_user)
):
    item = crud_item.get_include_common(session, current_user.id, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="item not found")
    return item


# StreamingResponse: https://fastapi.tiangolo.com/advanced/custom-response/#streamingresponse
# FileResponse: https://fastapi.tiangolo.com/advanced/custom-response/#fileresponse
@router.get("/items/{item_id}/download", response_class=StreamingResponse)
def download(
    item_id: int,
    session: Session = Depends(session.get_session),
    current_user: User = Depends(auth.get_current_active_user)
):
    item = crud_item.get_include_common(session, current_user.id, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="item not found")
    
    # ファイルダウンロード: https://github.com/tiangolo/fastapi/issues/1277#issuecomment-860101192
    return StreamingResponse(
        # io.StringIO, io.BytesIO は文字列・バイト列をストリームとして扱うことができる
        # https://docs.python.org/ja/3/library/io.html#text-i-o
        content=io.StringIO(item.content),
        # media_type="text/plain",
        headers={
            # Content-Disposition: https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Content-Disposition
            "Content-Disposition": f"attachment; filename={item.name}.{item.data_format.lower()}",
            # Content-Type: https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Content-Type
            "Content-Type" : "text/plain; charset=UTF-8",
        },
    )


@router.put("/items/{item_id}", response_model=ItemSchema)
async def update(
    item_id: int,
    name: str = Form(...),
    file: UploadFile = File(...),
    is_common: bool = Form(...),
    data_format: ItemDataFormat = Form(...),
    session: Session = Depends(session.get_session),
    current_user: User = Depends(auth.get_current_active_user)
):
    item = crud_item.get(session, current_user.id, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="item not found")

    content = await file.read()
    try:
        return crud_item.update(
            session,
            name=name,
            content=content.decode("utf-8"),
            is_common=is_common,
            data_format=data_format,
            item=item,
        )
    except Exception as e:
        logging_error_exception(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


@router.delete("/items/{item_id}")
def delete(
    item_id: int,
    session: Session = Depends(session.get_session),
    current_user: User = Depends(auth.get_current_active_user)
):
    item = crud_item.get(session, current_user.id, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="item not found")
    try:
        crud_item.delete(
            session,
            item=item,
        )
    except Exception as e:
        logging_error_exception(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")
    return {"item_id": item_id}