#!/usr/bin/env bash
# test-chat.sh — Send a chat completion request to the proxy
#
# Tests both model routes by default, or a specific model if passed.
#
# Usage:
#   ./scripts/test-chat.sh                        # test both models
#   ./scripts/test-chat.sh gpt-4o-mini            # test one model
#   MODEL=gpt-4o PROMPT="Tell me a joke" ./scripts/test-chat.sh

set -euo pipefail

PROXY_URL="${PROXY_URL:-http://localhost:8000}"
MASTER_KEY="${MASTER_KEY:-local-dev}"
PROMPT="${PROMPT:-Say hi in exactly one sentence.}"
MAX_TOKENS="${MAX_TOKENS:-128}"

# Colour helpers
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

run_test() {
  local model="$1"
  echo -e "\n${BOLD}${CYAN}--- Model: ${model} ---${RESET}"
  echo -e "Prompt: \"${PROMPT}\""

  local body
  body=$(printf '{"model":"%s","messages":[{"role":"user","content":"%s"}],"max_tokens":%s}' \
    "$model" "$PROMPT" "$MAX_TOKENS")

  local response http_status
  response=$(curl -s -w '\n__STATUS__%{http_code}' \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MASTER_KEY}" \
    -d "$body" \
    "${PROXY_URL}/v1/chat/completions")

  http_status=$(echo "$response" | tail -1 | sed 's/__STATUS__//')
  response=$(echo "$response" | sed '$d')

  if [ "$http_status" = "200" ]; then
    echo -e "${GREEN}✅ HTTP ${http_status}${RESET}"
    # Extract and print just the assistant's reply
    local reply
    reply=$(echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['choices'][0]['message']['content'])
" 2>/dev/null) || reply="(could not parse reply)"
    echo -e "Reply: ${BOLD}${reply}${RESET}"
    # Print full JSON if VERBOSE is set
    if [ "${VERBOSE:-}" = "1" ]; then
      echo "$response" | python3 -m json.tool
    fi
  else
    echo -e "${RED}❌ HTTP ${http_status}${RESET}"
    echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
    return 1
  fi
}

# Determine which models to test
if [ $# -ge 1 ]; then
  MODELS=("$@")
elif [ -n "${MODEL:-}" ]; then
  MODELS=("$MODEL")
else
  MODELS=("gpt-4o-mini" "gpt-4o")
fi

PASS=0
FAIL=0

for model in "${MODELS[@]}"; do
  if run_test "$model"; then
    ((PASS++)) || true
  else
    ((FAIL++)) || true
  fi
done

echo -e "\n${BOLD}Results: ${GREEN}${PASS} passed${RESET}${BOLD}, ${RED}${FAIL} failed${RESET}"
[ "$FAIL" -eq 0 ]
