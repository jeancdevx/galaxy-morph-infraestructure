"""Build deps.zip with job modules + shared libs, excluding the entrypoint."""
from __future__ import annotations

import os
import sys
import zipfile

BUILD_DIR = sys.argv[1]
JOB_SRC = sys.argv[2]
LIBS_SRC = sys.argv[3]

os.makedirs(BUILD_DIR, exist_ok=True)
out = os.path.join(BUILD_DIR, "deps.zip")

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(JOB_SRC):
        for name in files:
            if name.endswith(".py") and name != "main_streaming.py":
                full = os.path.join(root, name)
                zf.write(full, os.path.relpath(full, JOB_SRC))
    for root, _, files in os.walk(LIBS_SRC):
        for name in files:
            if name.endswith(".py"):
                full = os.path.join(root, name)
                zf.write(full, os.path.relpath(full, LIBS_SRC))

print(f"Built: {out}")
