#!/usr/bin/env bash

# Helper function to merge TOML content into a file
merge_toml() {
  local target_file="$1"
  local new_toml_content="$2"

  python3 - "$target_file" "$new_toml_content" <<'EOF'
import sys
import re

target_path = sys.argv[1]
new_content = sys.argv[2]

# Simple inline TOML list extractor helper for basic TOML structures
def parse_simple_toml(text):
    data = {}
    current_section = None

    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue

        # Section header e.g. [lint]
        if line.startswith('[') and line.endswith(']'):
            current_section = line[1:-1].strip()
            if current_section not in data:
                data[current_section] = {}
            continue

        # Key-Value pairs e.g. key = "value" or key = ["A", "B"]
        if '=' in line:
            key, val = line.split('=', 1)
            key = key.strip()
            val = val.strip()

            # Extract array elements if value is a list
            if val.startswith('[') and val.endswith(']'):
                items = re.findall(r'"([^"]*)"|\'([^\']*)\'', val)
                val = [item[0] or item[1] for item in items]

            if current_section:
                data[current_section][key] = val
            else:
                data[key] = val

    return data

# Load existing content if file exists
import os
existing_text = ""
if os.path.exists(target_path):
    with open(target_path, "r") as f:
        existing_text = f.read()

existing_data = parse_simple_toml(existing_text)
new_data = parse_simple_toml(new_content)

# Merge logic: Combine dictionary and extend/unique list items
for section, content in new_data.items():
    if isinstance(content, dict):
        if section not in existing_data or not isinstance(existing_data[section], dict):
            existing_data[section] = {}
        for k, v in content.items():
            if isinstance(v, list) and k in existing_data[section] and isinstance(existing_data[section][k], list):
                # Union of lists preserving order
                combined = existing_data[section][k] + [item for item in v if item not in existing_data[section][k]]
                existing_data[section][k] = combined
            else:
                existing_data[section][k] = v
    else:
        existing_data[content] = new_data[section]

# Reconstruct TOML format
output = []
# Top level keys
for k, v in existing_data.items():
    if not isinstance(v, dict):
        output.append(f'{k} = {repr(v).lower() if isinstance(v, bool) else repr(v)}')

# Tables / Sections
for section, keys in existing_data.items():
    if isinstance(keys, dict):
        output.append(f"\n[{section}]")
        for k, v in keys.items():
            if isinstance(v, list):
                items_str = ", ".join([f'"{item}"' for item in v])
                output.append(f'{k} = [{items_str}]')
            else:
                output.append(f'{k} = {repr(v).lower() if isinstance(v, bool) else repr(v)}')

with open(target_path, "w") as f:
    f.write("\n".join(output) + "\n")

EOF

  echo "[✔] Merged configuration into '$target_file'"
}

# --- Command Line Argument Handler ---
if [[ $# == 0 ]]; then
  shopt -s nullglob
  py_files=(*.py)

  # Check if the array contains any elements
  if ((${#py_files[@]} > 0)); then
    arg+=('py')
  fi
fi
for arg in "$@"; do
  echo "$arg"
  case "$arg" in
  py | python)
    read -r -d '' py_content <<'EOF'
line-length = 120
indent-width = 2
target-version = "py313"

[lint]
select = ["B", "C", "E", "F", "W", "I", "N", "Q", "UP", "RET", "RSE", "RUF", "ISC", "PLC", "PLE", "PLW", "T20", "PERF"]
ignore = ["N802", "Q000", "N816", "T201", "N806", "B011", "C901", "N818", "PLC0415", "PLC1802", "PLC1901", "PLE1141", "UP015"]
EOF

    merge_toml "ruff.toml" "$py_content"
    ;;
  go)
    read -r r
    if [[ "$r" == *github.com/rsa17826* ]]; then
      go mod init "$r"
    else
      go mod init "github.com/rsa17826/$r"
    fi
    ;;
  esac
done
