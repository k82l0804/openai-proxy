# AGENTS.md

A [LiteLLM](https://docs.litellm.ai/) proxy that exposes many upstream models (mostly through OpenRouter) under
OpenAI-compatible names at `http://localhost:8000`. Coding-agent containers (e.g. `ai-vendor-agent-cli-containers`)
attach to its compose network, `openai-proxy_default`.

## Layout

| Path | What it is |
|---|---|
| `litellm_config.yaml` | The model routes (`model_list`), aliases (`router_settings.model_group_alias`) and `general_settings`. The header comment lists every route; keep it in sync. |
| `docker-compose.yml` | One service, `llm-proxy`, from `ghcr.io/berriai/litellm:main-stable`. Mounts the config and `agy_callbacks.py` read-only. |
| `agy_callbacks.py` | A LiteLLM callback that fixes agy (Antigravity CLI) tool results on the Gemini `/v1beta` route. |
| `Makefile` | `up`, `down`, `logs`, `health`, `test`. |
| `scripts/` | `test-chat.sh`, `test-streaming.sh`, `list-models.sh`, `health-check.sh`, `agy-proxy.sh`. |
| `.env` (gitignored) | `LITELLM_MASTER_KEY` and the provider keys. See `.env.example`. |

## Rules

- **Never read, print or log secret values from `.env`.** Check only that a key is non-empty. Scripts that need the
  proxy key read only the `LITELLM_MASTER_KEY=` line (see `scripts/agy-proxy.sh`); never `source` the whole `.env`,
  because it also holds the upstream provider keys.
- **Don't rename the folder.** Compose derives the project name from it, which gives the network
  `openai-proxy_default` that other projects attach to.
- **Engine-agnostic.** It must work with Docker (Desktop or Engine) and with rootless Podman, on WSL 2 and on a normal
  Linux host. Use `$(COMPOSE)` in the Makefile, never a hardcoded `docker compose`. Image names are fully qualified
  (`ghcr.io/…`, `docker.io/…`).
- **Healthcheck arguments contain no spaces.** Podman's Docker-compatible API splits `CMD` arguments on spaces. The
  image has no `curl`; the healthcheck uses `python3`.
- When you add a model route, also add it to the config's header comment, and to `make test` if it's one of the
  routes worth smoke-testing.

## Checking changes

```bash
make up && make health                  # proxy starts and answers /health/liveliness
./scripts/list-models.sh                # the master key works and the routes are loaded
./scripts/test-chat.sh <model>          # one route end to end (needs that provider's key in .env)
make test                               # every route in the Makefile (spends a few tokens per route)
```

Container status should become `healthy` after about 20 s (`docker ps` / `podman ps`).
