#!/usr/bin/env python3
"""Compatibility entry point that writes all locale fallback metadata."""
from __future__ import annotations

import sys

from generate_metadata import main


if "--write" not in sys.argv:
    sys.argv.insert(1, "--write")


if __name__ == "__main__":
    raise SystemExit(main())
