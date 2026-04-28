import uvicorn
import argparse
import os
from pathlib import Path
from api.main import app

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run the FastAPI server")
    parser.add_argument(
        "--port", type=int, required=True, help="Port number to run the server on"
    )
    parser.add_argument(
        "--reload", type=str, default="false", help="Reload the server on code changes"
    )
    args = parser.parse_args()
    reload = args.reload == "true"
    host = "127.0.0.1"

    # Always bind absolute asset generation to the active runtime port.
    os.environ["FASTAPI_PUBLIC_URL"] = f"http://{host}:{args.port}"

    # Set export-related environment variables if not already set
    if not os.environ.get("NEXT_PUBLIC_URL"):
        os.environ["NEXT_PUBLIC_URL"] = "http://localhost:3000"

    if not os.environ.get("NEXT_PUBLIC_FAST_API"):
        os.environ["NEXT_PUBLIC_FAST_API"] = f"http://{host}:{args.port}"

    if not os.environ.get("EXPORT_PACKAGE_ROOT"):
        # Try to find the presentation-export directory
        current_dir = Path(__file__).parent.resolve()
        export_dir = current_dir.parent.parent.parent / "presentation-export"
        if export_dir.exists():
            os.environ["EXPORT_PACKAGE_ROOT"] = str(export_dir)

    # Debug: Print export configuration
    print(f"[Export Config] FASTAPI_PUBLIC_URL: {os.environ.get('FASTAPI_PUBLIC_URL')}")
    print(f"[Export Config] NEXT_PUBLIC_URL: {os.environ.get('NEXT_PUBLIC_URL')}")
    print(f"[Export Config] NEXT_PUBLIC_FAST_API: {os.environ.get('NEXT_PUBLIC_FAST_API')}")
    print(f"[Export Config] EXPORT_PACKAGE_ROOT: {os.environ.get('EXPORT_PACKAGE_ROOT')}")

    uvicorn.run(
        "api.main:app",
        host=host,
        port=args.port,
        log_level="info",
        reload=reload,
    )
