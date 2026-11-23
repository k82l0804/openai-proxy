#!/usr/bin/env bash
# list-models.sh — List all models registered in the proxy
#
# Uses the OpenAI-compatible GET /v1/models endpoint.
#
# Usage: ./scripts/list-models.sh

set -euo pipefail

PROXY_URL="${PROXY_URL:-http://localhost:8000}"
# The proxy key: LITELLM_MASTER_KEY from ../.env (only that line; .env also holds the upstream provider keys)
MASTER_KEY="${MASTER_KEY:-$(grep -m1 '^LITELLM_MASTER_KEY=' "$(dirname "$0")/../.env" 2>/dev/null | cut -d= -f2- | tr -d '"' || true)}"
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
