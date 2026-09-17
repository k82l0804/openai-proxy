# OpenAI-Compatible Proxy

> Simulates locally-hosted LLM models for **Fox Code CLI** and **Fox ACP Client** development and testing.

In production, Fox is designed to work with locally-hosted models (Ollama, LM Studio, etc.) accessed at `http://localhost:8000`. This Docker setup runs a [LiteLLM](https://github.com/BerriAI/litellm) proxy that exposes Google Gemini under standard OpenAI-compatible model names — so the application code never needs to know about Google APIs.

---

## Model Mapping

| Model name (what Fox uses) | Backed by | Character |
|---|---|---|
| `gpt-4o-mini` | Gemini 2.0 Flash | Fast, cheap — default for most tasks |
| `gpt-4o` | Gemini 2.5 Flash | Smart, capable — complex reasoning |

Any OpenAI SDK client pointed at `http://localhost:8000` works transparently.

---

## Prerequisites

- [Docker Desktop](https://docs.docker.com/get-docker/) (or Docker Engine + Compose plugin)
- A **Gemini API key** — get one free at [aistudio.google.com/apikey](https://aistudio.google.com/apikey)

---

## Quick Start

```bash
# 1. Enter this directory
cd openai-proxy/

# 2. Create your .env from the example
cp .env.example .env

# 3. Edit .env and paste your real key
#    GEMINI_API_KEY=AIza...

# 4. Start the proxy
make up

# 5. Verify it's healthy
make health

# 6. Smoke-test both model routes
make test
```

The proxy is ready when `make health` returns `{"status": "healthy", ...}`.

---

## Usage from Fox CLI / ACP Client

Configure the Fox CLI or any OpenAI SDK client to point at the proxy:

```bash
# Environment variables (OpenAI SDK convention)
export OPENAI_BASE_URL=http://localhost:8000/v1
export OPENAI_API_KEY=local-dev   # the master_key set in litellm_config.yaml
```

Then make normal OpenAI API calls:

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8000/v1", api_key="local-dev")

response = client.chat.completions.create(
    model="gpt-4o-mini",   # → routed to Gemini 2.0 Flash
    messages=[{"role": "user", "content": "Hello!"}],
)
print(response.choices[0].message.content)
```

---

## Available `make` Targets

| Command | Description |
|---|---|
| `make up` | Start the proxy in the background |
| `make down` | Stop the proxy |
| `make logs` | Tail proxy logs (Ctrl-C to exit) |
| `make health` | Check if the proxy is responding |
| `make test` | Send a test request against both model routes |

---

## Configuration

Edit [`litellm_config.yaml`](./litellm_config.yaml) to:
- Add more model routes (e.g. a `gpt-4-turbo` alias for Gemini 1.5 Pro)
- Change the backend model versions
- Set a different `master_key` for shared environments
- Enable Redis caching, request logging, etc.

See the [LiteLLM docs](https://docs.litellm.ai/docs/proxy/configs) for all options.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `No .env file found` | Run `cp .env.example .env` and fill in your key |
| `make health` fails | Wait ~20s for the container to start, then retry |
| 401 Unauthorized from proxy | Ensure you're passing `Authorization: Bearer local-dev` |
| 400 from Gemini | Check `GEMINI_API_KEY` is set correctly in `.env` |
| Port 8000 already in use | Change `8000:8000` to e.g. `8001:8000` in `docker-compose.yml` |

---

## Architecture Note

```
Fox CLI / ACP Client
        │
        │  POST /v1/chat/completions
        │  model: "gpt-4o-mini"
        ▼
 LiteLLM Proxy (localhost:8000)
        │
        │  Routes to gemini/gemini-2.0-flash
        ▼
 Google Gemini API
```

This indirection means the Fox application code is **fully agnostic** to the model provider. Swapping to a real local model (Ollama, vLLM, etc.) in production requires only changing `litellm_config.yaml` — zero application code changes.
