from fastapi import APIRouter, Response

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.get("/verify")
async def verify():
    return Response(status_code=200)
