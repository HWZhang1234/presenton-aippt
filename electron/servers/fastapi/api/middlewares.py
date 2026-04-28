from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

from utils.get_env import get_can_change_keys_env
from utils.user_config import update_env_with_user_config, update_env_with_request_headers


class UserConfigEnvUpdateMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if get_can_change_keys_env() != "false":
            # First, try to read config from HTTP headers (for web mode)
            # If no headers are present, fall back to file-based config (for Electron mode)
            headers_applied = update_env_with_request_headers(request)
            
            # Only load from file if no headers were found
            if not headers_applied:
                update_env_with_user_config()
        return await call_next(request)
