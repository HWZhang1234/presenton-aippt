from pathlib import Path
import sys
import os


FASTAPI_ROOT = Path(__file__).resolve().parents[1]
if str(FASTAPI_ROOT) not in sys.path:
    sys.path.insert(0, str(FASTAPI_ROOT))


from services.icon_finder_service import ICON_FINDER_SERVICE


def main() -> None:
    # Initialize the icon finder service to warm the fastembed cache
    try:
        ICON_FINDER_SERVICE._initialize_icons_collection()
        print(
            f"Fastembed cache prepared at {ICON_FINDER_SERVICE.cache_directory}"
        )
    except Exception as e:
        print(f"Warning: Failed to warm fastembed cache: {e}")
        # Don't fail the build, just warn
        pass


if __name__ == "__main__":
    main()
