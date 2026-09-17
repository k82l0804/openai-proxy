#!/usr/bin/env bash
# health-check.sh — Verify the proxy is up and responding
#
# Usage: ./scripts/health-check.sh
#        PROXY_URL=http://localhost:9000 ./scripts/health-check.sh

set -euo pipefail

PROXY_URL="${PROXY_URL:-http://localhost:8000}"

echo "🔍 Checking proxy health at ${PROXY_URL} ..."

RESPONSE=$(curl -sf "${PROXY_URL}/health/liveliness" 2>/dev/null) || {
  echo "❌ Proxy is not responding at ${PROXY_URL}"
  echo "   Is it running? Try: make up"
  exit 1
}

echo "✅ Proxy is healthy: ${RESPONSE}"
