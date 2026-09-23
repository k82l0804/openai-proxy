.PHONY: up down logs health test

PROXY_URL := http://localhost:8000
MASTER_KEY := local-dev

## Start the proxy and wait until healthy (up to 60s)
up:
	@if [ ! -f .env ]; then \
		echo "⚠️  No .env file found. Copy .env.example and fill in your key:"; \
		echo "   cp .env.example .env"; \
		exit 1; \
	fi
	docker compose up -d
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
	docker compose down

## Tail proxy logs (Ctrl-C to exit)
logs:
	docker compose logs -f

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
	@echo "--- Testing nemotron (-> Nemotron 3 Ultra) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"nemotron","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing gemma (-> Gemma 4 31B) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"gemma","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
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
	@echo "--- Testing llama-3.1 (-> Llama 3.1 8B Instruct) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"llama-3.1","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
	@echo "--- Testing llama-3.3 (-> Llama 3.3 70B Instruct) ---"
	@RESP=$$(curl -s -H "Content-Type: application/json" \
		-H "Authorization: Bearer $(MASTER_KEY)" \
		-d '{"model":"llama-3.3","messages":[{"role":"user","content":"Say hi in one sentence."}],"max_tokens":64}' \
		$(PROXY_URL)/v1/chat/completions); \
	echo "$$RESP" | python3 -m json.tool || echo "$$RESP"
