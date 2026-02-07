from pathlib import Path
import sys


# Ensure "app" package is importable when pytest runs from repo root.
ML_SERVICE_ROOT = Path(__file__).resolve().parents[1]
if str(ML_SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(ML_SERVICE_ROOT))
