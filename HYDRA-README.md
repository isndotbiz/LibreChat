# HYDRA Enterprise

HYDRA Enterprise is a LibreChat-based LLM security evaluation platform with HYDRA red-team tooling, OpenRouter-first model routing, and production deployment scaffolding.

## Architecture (Text Diagram)
- `LibreChat API/UI` -> user chat, auth, endpoint routing, tool calling
- `HYDRA Tool Bridge` -> structured tools (`hydra_evaluate`, `hydra_ip_score`, `hydra_techniques`, `hydra_status`)
- `Python HYDRA Layer` -> `api/hydra/hydra_evaluate.py` + `hydra_pipeline.py` + `hydra_core.py`
- `Datastores` -> MongoDB (LibreChat core), PostgreSQL (HYDRA analytics), Redis (cache/rate/session)
- `Edge` -> Nginx reverse proxy with SSE-safe streaming config
- `Optional Services` -> HYDRA Dashboard, Telegram bot

## Quick Start (3 commands)
```bash
cp .env.example .env
docker compose -f docker-compose.hydra.yml up -d --build
curl -sf http://localhost/health
```

## Features
- Curated OpenRouter model menu for HYDRA workflows
- HYDRA structured tools integrated into LibreChat tool system
- Python bridge for cascade execution and PostgreSQL-backed analytics
- MCP server registration entries for Dashboard and RAG resources
- HYDRA Enterprise branding (title, login copy, favicon, dark theme, chat backdrop)
- Production compose + nginx config templates for Debian VPS deployment

## Screenshots
- TODO: add login, chat, tool panel, and dashboard screenshots

## License
- Base stack: LibreChat (MIT), see `LICENSE`
- Third-party attribution: `THIRD_PARTY_LICENSES`
- HYDRA proprietary layer: `LICENSE.hydra`
