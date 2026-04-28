from typing import Annotated, List
from fastapi import APIRouter, Body, HTTPException

from utils.available_models import list_available_openai_compatible_models

OPENAI_ROUTER = APIRouter(prefix="/openai", tags=["OpenAI"])


@OPENAI_ROUTER.post("/models/available", response_model=List[str])
async def get_available_models(
    url: Annotated[str, Body()],
    api_key: Annotated[str, Body()],
):
    print(f"[DEBUG] Received request - URL: '{url}', API Key length: {len(api_key) if api_key else 0}")
    try:
        return await list_available_openai_compatible_models(url, api_key)
    except Exception as e:
        print(f"[DEBUG] Exception in get_available_models: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
