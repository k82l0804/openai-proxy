#!/usr/bin/env bash
# list-models.sh — List all models registered in the proxy
#
# Uses the OpenAI-compatible GET /v1/models endpoint.
#
# Usage: ./scripts/list-models.sh

set -euo pipefail

PROXY_URL="${PROXY_URL:-http://localhost:8000}"
MASTER_KEY="${MASTER_KEY:-local-dev}"

echo "📋 Models available at ${PROXY_URL}:"
echo ""

response=$(curl -sf \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  "${PROXY_URL}/v1/models") || {
  echo "❌ Could not reach proxy. Is it running? Try: make up"
  exit 1
}

echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
models = data.get('data', [])
if not models:
    print('  (no models found)')
else:
    for m in models:
        print(f'  • {m[\"id\"]}')
print(f'\nTotal: {len(models)} model(s)')
"
