#!/usr/bin/env bash
# test-streaming.sh — Test streaming chat completions (SSE)
#
# Sends a request with stream=true and prints tokens as they arrive.
#
# Usage:
#   ./scripts/test-streaming.sh
#   ./scripts/test-streaming.sh gpt-4o
#   MODEL=gpt-4o-mini PROMPT="Count to 5" ./scripts/test-streaming.sh

set -euo pipefail

PROXY_URL="${PROXY_URL:-http://localhost:8000}"
MASTER_KEY="${MASTER_KEY:-local-dev}"
MODEL="${1:-${MODEL:-gpt-4o-mini}}"
PROMPT="${PROMPT:-Count from 1 to 5, one number per line.}"
MAX_TOKENS="${MAX_TOKENS:-128}"

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${BOLD}${CYAN}--- Streaming: ${MODEL} ---${RESET}"
echo -e "Prompt: \"${PROMPT}\"\n"
echo -ne "Reply: ${BOLD}"

body=$(printf '{"model":"%s","messages":[{"role":"user","content":"%s"}],"max_tokens":%s,"stream":true}' \
  "$MODEL" "$PROMPT" "$MAX_TOKENS")

# Stream the SSE response and extract delta content tokens
curl -sN \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -d "$body" \
  "${PROXY_URL}/v1/chat/completions" | \
  while IFS= read -r line; do
    # SSE lines look like: data: {...}
    if [[ "$line" == data:* ]]; then
      payload="${line#data: }"
      [ "$payload" = "[DONE]" ] && break
      # Extract delta.content if present
      token=$(echo "$payload" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    t = d['choices'][0]['delta'].get('content', '')
    if t: print(t, end='', flush=True)
except: pass
" 2>/dev/null) || true
      printf "%s" "$token"
    fi
  done

echo -e "${RESET}\n"
echo -e "${GREEN}✅ Streaming complete${RESET}"
