#!/bin/bash
# Usage: ./galaxy_get.sh <dataset_id> <destination_dir>

DATASET_ID=$1
DEST_DIR=${2:-.}  # defaults to current directory
API_KEY="YOUR_API_KEY"
GALAXY_URL="http://localhost"

if [ -z "$DATASET_ID" ]; then
    echo "Usage: $0 <dataset_id> [destination_dir]"
    exit 1
fi

INFO=$(curl -s "$GALAXY_URL/api/datasets/$DATASET_ID" -H "x-api-key: $API_KEY")
FORMAT=$(echo $INFO | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['extension'])")
FILEPATH=$(echo $INFO | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['file_name'])")
NAME=$(echo $INFO | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['name'])")

# Sanitize name (remove spaces and special chars)
SAFE_NAME=$(echo "$NAME" | tr ' /' '__')

cp "$FILEPATH" "$DEST_DIR/${SAFE_NAME}.${FORMAT}"
echo "Saved: $DEST_DIR/${SAFE_NAME}.${FORMAT}"