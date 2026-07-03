#!/usr/bin/env python3
"""Read a dotted JSON path from stdin and print a scalar value."""
import json
import sys

path = sys.argv[1].split('.') if len(sys.argv) > 1 else []
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

value = data
for part in path:
    if isinstance(value, dict) and part in value:
        value = value[part]
    else:
        sys.exit(0)

if isinstance(value, bool):
    print('true' if value else 'false')
elif isinstance(value, (str, int, float)):
    print(value)
