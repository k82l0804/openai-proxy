.PHONY: up down logs health test

PROXY_URL := http://localhost:8000

# The proxy key: LITELLM_MASTER_KEY from .env (only that line is read; .env also holds the upstream provider keys).
# Falls back to local-dev, the key older setups used. Override with: make test MASTER_KEY=...
ifndef MASTER_KEY
MASTER_KEY := $(or $(shell sed -n 's/^LITELLM_MASTER_KEY=//p' .env 2>/dev/null | head -n1 | tr -d '"'),local-dev)
endif

# Container engine: Docker Compose v2 if available (also true with podman-docker), else podman compose, else the
# standalone docker-compose. Override with: make up COMPOSE="podman compose"
ifndef COMPOSE
COMPOSE := $(shell \
	if docker compose version >/dev/null 2>&1; then echo "docker compose"; \
	elif podman compose version >/dev/null 2>&1; then echo "podman compose"; \
	elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; fi)
endif

## Start the proxy and wait until healthy (up to 60s)
up:
	@if [ ! -f .env ]; then \
		echo "⚠️  No .env file found. Copy .env.example and fill in your key:"; \
		echo "   cp .env.example .env"; \
		exit 1; \
	fi
	@if [ -z "$(COMPOSE)" ]; then \
		echo "❌ No compose command found. Install Docker (with the Compose plugin) or Podman (with podman compose)."; \
		exit 1; \
	fi
	$(COMPOSE) up -d
	@echo "⏳ Waiting for proxy to be ready..."
	@for i in $$(seq 1 12); do \
		if curl -sf $(PROXY_URL)/health/liveliness > /dev/null 2>&1; then \
			echo "✅ Proxy is ready at $(PROXY_URL)"; \
			exit 0; \
		fi; \
		echo "   ... waiting ($$i/12)"; \
		sleep 5; \
	done; \
	echo "❌ Proxy did not become healthy in time. Run 'make logs' to debug."; \
	exit 1

## Stop the proxy
down:
	$(COMPOSE) down

## Tail proxy logs (Ctrl-C to exit)
logs:
	$(COMPOSE) logs -f

## Check if the proxy is healthy (unauthenticated liveness endpoint)
health:
	@echo "Checking $(PROXY_URL)/health/liveliness ..."
	@curl -sf $(PROXY_URL)/health/liveliness | python3 -m json.tool || \
		(echo "❌ Proxy is not responding. Is it running? Try: make up" && exit 1)

## Send a test completion request against both model routes
test:
	@echo "--- Testing gpt-4o-mini (-> Gemini 2.5 Flash) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing nemotron-3-ultra (-> Nemotron 3 Ultra) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"nemotron-3-ultra","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing gemma-4 (-> Gemma 4 31B) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"gemma-4","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing gpt-oss (-> GPT-OSS 120B) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"gpt-oss","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing codestral (-> Codestral 2508) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"codestral","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing llama-3.2-3b (-> Llama 3.2 3B Instruct) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"llama-3.2-3b","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing llama-3.1-8b (-> Llama 3.1 8B Instruct) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"llama-3.1-8b","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing qwen-2.5-7b-instruct (-> Qwen 2.5 7B Instruct) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"qwen-2.5-7b-instruct","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing llama-3.3 (-> Llama 3.3 70B Instruct) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"llama-3.3","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing deepseek-v4-flash (-> DeepSeek V4 Flash) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
