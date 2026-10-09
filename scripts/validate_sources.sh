#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILES_DIR="$REPO_ROOT/data/profiles"

echo "=== Validating Data Profile Sources (HTTP 200) ==="

FAILED=0
TOTAL=0

URLS=$(python3 - <<EOF
import os, json, sys

profiles_dir = "$PROFILES_DIR"
urls = []
for fname in sorted(os.listdir(profiles_dir)):
    if fname.startswith('.') or not fname.endswith('.json') or fname == 'schema.json':
        continue
    filepath = os.path.join(profiles_dir, fname)
    with open(filepath, 'r') as f:
        data = json.load(f)
        for url in data.get('sources', []):
            if url.startswith('http://') or url.startswith('https://'):
                print(f"{fname}\t{url}")
EOF
)

if [ -z "$URLS" ]; then
    echo "ERROR: No URLs found to validate in $PROFILES_DIR"
    exit 1
fi

while IFS=$'\t' read -r profile_file url; do
    [ -z "$url" ] && continue
    TOTAL=$((TOTAL + 1))
    printf "Checking [%s] %s ... " "$profile_file" "$url"
    HTTP_CODE=$(curl -s -L -o /dev/null -w "%{http_code}" --connect-timeout 15 --max-time 30 -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)" "$url" || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "OK (200)"
    else
        echo "FAIL (HTTP $HTTP_CODE)"
        FAILED=$((FAILED + 1))
    fi
done <<< "$URLS"

echo ""
echo "=== Summary: $TOTAL URLs checked, $FAILED failures ==="

if [ "$FAILED" -ne 0 ]; then
    echo "Error: $FAILED source URLs failed HTTP 200 validation."
    exit 1
fi

echo "All sources successfully validated with HTTP 200."
exit 0
