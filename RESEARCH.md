# HYDRA Research Notes (LibreChat Extension Points)

## 1) Custom Model Providers
- Config source: `librechat.yaml` under `endpoints.custom`.
- Endpoint route resolution: `api/server/routes/endpoints.js` and `api/server/controllers/EndpointController`.
- Model list route: `api/server/routes/models.js`.
- Practical result: OpenRouter works cleanly as a custom endpoint with `apiKey`, `baseURL`, curated `models.default`, and `fetch: false`.

## 2) Custom Tools
- Tool manifest source: `api/app/clients/tools/manifest.json`.
- Tool implementation classes: `api/app/clients/tools/structured/*.js` extending `@langchain/core/tools` `Tool`.
- Tool registration export: `api/app/clients/tools/index.js`.
- Runtime loading + auth + MCP blending: `api/app/clients/tools/util/handleTools.js`.
- Assistant tool formatting bootstrap: `api/server/services/start/tools.js`.
- Practical result: HYDRA tools added as structured tools:
  - `hydra_evaluate`
  - `hydra_ip_score`
  - `hydra_techniques`
  - `hydra_status`

## 3) TTS / STT Configuration
- API routes:
  - `api/server/routes/files/speech/tts.js`
  - `api/server/routes/files/speech/stt.js`
  - `api/server/routes/files/speech/customConfigSpeech.js`
- Runtime services:
  - `api/server/services/Files/Audio/TTSService.js`
  - `api/server/services/Files/Audio/STTService.js`
  - `api/server/services/Files/Audio/getVoices.js`
- Config schema location: `appConfig.speech.tts` and `appConfig.speech.stt` in `librechat.yaml`.
- Important constraint: TTS and STT each require exactly one active provider at a time in current service logic.

## 4) Frontend Theme + Branding
- Global CSS variables: `client/src/style.css`.
- Tailwind variable wiring: `client/tailwind.config.cjs`.
- Startup title logic: `client/src/routes/Layouts/Startup.tsx`.
- Login shell: `client/src/components/Auth/AuthLayout.tsx`.
- Static HTML title/meta/favicon: `client/index.html`.
- Chat viewport surface hook: `client/src/components/Chat/Messages/MessagesView.tsx`.

## 5) MCP Integration
- MCP startup/registry bootstrap: `api/server/services/initializeMCPs.js`.
- Runtime MCP services: `api/server/services/MCP.js`.
- Route/controller surface: `api/server/routes/mcp.js`, `api/server/controllers/mcp.js`.
- Config entries:
  - `mcpSettings.allowedDomains`
  - `mcpServers` in `librechat.yaml`
- Practical result: `hydra_dashboard` and `hydra_rag` MCP server entries added in config.
