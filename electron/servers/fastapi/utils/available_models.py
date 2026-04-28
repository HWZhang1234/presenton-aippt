from anthropic import AsyncAnthropic
from openai import AsyncOpenAI
from google import genai
import httpx
import os


async def list_available_openai_compatible_models(url: str, api_key: str) -> list[str]:
    # Check if SSL verification should be disabled
    disable_ssl = os.getenv("DISABLE_SSL_VERIFY", "false").lower() == "true"
    
    # Get proxy settings
    http_proxy = os.getenv("HTTP_PROXY") or os.getenv("http_proxy")
    https_proxy = os.getenv("HTTPS_PROXY") or os.getenv("https_proxy")
    
    print(f"[DEBUG] Environment - DISABLE_SSL_VERIFY: {os.getenv('DISABLE_SSL_VERIFY')}, disable_ssl: {disable_ssl}")
    print(f"[DEBUG] Environment - HTTP_PROXY: {http_proxy}, HTTPS_PROXY: {https_proxy}")
    
    # Configure httpx client with proxy and SSL settings
    client_kwargs = {}
    if disable_ssl or http_proxy or https_proxy:
        httpx_kwargs = {}
        if disable_ssl:
            httpx_kwargs["verify"] = False
        if https_proxy:
            # Use the HTTPS proxy for HTTPS connections
            httpx_kwargs["proxy"] = https_proxy
        elif http_proxy:
            # Fallback to HTTP proxy
            httpx_kwargs["proxy"] = http_proxy
        http_client = httpx.AsyncClient(**httpx_kwargs)
        client_kwargs["http_client"] = http_client
    
    client = AsyncOpenAI(api_key=api_key, base_url=url, **client_kwargs)
    
    try:
        response = await client.models.list()
        models = response.data if hasattr(response, 'data') else []
        
        if models:
            return list(map(lambda x: x.id, models))
        print(f"[DEBUG] OpenAI client returned empty models list, trying HTTP fallback")
        # Fall through to HTTP fallback
    except Exception as e:
        print(f"[DEBUG] OpenAI client failed: {str(e)}, trying HTTP fallback")
    
    # Try direct HTTP request for custom APIs (fallback)
    try:
        httpx_kwargs = {}
        if disable_ssl:
            httpx_kwargs["verify"] = False
        if https_proxy:
            httpx_kwargs["proxy"] = https_proxy
        elif http_proxy:
            httpx_kwargs["proxy"] = http_proxy
        
        async with httpx.AsyncClient(**httpx_kwargs) as http_client:
            headers = {"Authorization": f"Bearer {api_key}"}
            response = await http_client.get(f"{url}/models", headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                print(f"[DEBUG] HTTP fallback got response: {len(data.get('models', []))} models")
                
                # Handle Qualcomm API format: {"models": [...]}
                if "models" in data:
                    model_list = []
                    for model in data["models"]:
                        # Each model has a "name" array with aliases
                        if "name" in model and isinstance(model["name"], list):
                            # Use the first name as the primary identifier
                            if model["name"]:
                                model_list.append(model["name"][0])
                    print(f"[DEBUG] Returning {len(model_list)} models")
                    return model_list
                
                # Handle standard OpenAI format: {"data": [...]}
                elif "data" in data:
                    return [m["id"] for m in data["data"]]
            
            return []
    except Exception as http_error:
        print(f"[DEBUG] HTTP fallback failed: {str(http_error)}")
        raise Exception(f"HTTP fallback error: {str(http_error)}")


async def list_available_anthropic_models(api_key: str) -> list[str]:
    client = AsyncAnthropic(api_key=api_key)
    return list(map(lambda x: x.id, (await client.models.list(limit=50)).data))


async def list_available_google_models(api_key: str) -> list[str]:
    client = genai.Client(api_key=api_key)
    return list(map(lambda x: x.name, client.models.list(config={"page_size": 50})))
