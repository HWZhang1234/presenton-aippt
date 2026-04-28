from fastapi import HTTPException
from anthropic import APIError as AnthropicAPIError
from openai import APIError as OpenAIAPIError, RateLimitError, InternalServerError
from google.genai.errors import APIError as GoogleAPIError
import traceback


def handle_llm_client_exceptions(e: Exception) -> HTTPException:
    traceback.print_exc()
    
    # Handle OpenAI-style errors (including custom LLM providers using OpenAI SDK)
    if isinstance(e, RateLimitError):
        return HTTPException(
            status_code=429, 
            detail="API rate limit exceeded. Please wait a moment and try again."
        )
    
    if isinstance(e, InternalServerError):
        error_msg = str(e)
        # Check for throttling/rate limit errors in the message
        if "ThrottlingException" in error_msg or "Too many tokens" in error_msg:
            return HTTPException(
                status_code=429,
                detail="API rate limit exceeded. Please wait a moment and try again."
            )
        # Check for other common error patterns
        if "EXTERNAL_API_ERROR" in error_msg:
            return HTTPException(
                status_code=502,
                detail=f"External API error: {error_msg}"
            )
        return HTTPException(status_code=500, detail=f"API server error: {error_msg}")
    
    if isinstance(e, OpenAIAPIError):
        return HTTPException(status_code=500, detail=f"OpenAI API error: {e.message}")
    
    if isinstance(e, GoogleAPIError):
        return HTTPException(status_code=500, detail=f"Google API error: {e.message}")
    
    if isinstance(e, AnthropicAPIError):
        return HTTPException(
            status_code=500, detail=f"Anthropic API error: {e.message}"
        )
    
    return HTTPException(status_code=500, detail=f"LLM API error: {e}")
