#!/bin/bash
set -euo pipefail

for file in *; do
  mv -- "$file" "$file.json"
done
