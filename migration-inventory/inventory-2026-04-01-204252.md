# LibreChat Migration Inventory

Generated: 2026-04-02T03:43:55Z
Source: live VPS 46.224.100.66 (MongoDB LibreChat)
Snapshot files:
- JSON: migration-inventory/inventory-2026-04-01-204252.json
- YAML: migration-inventory/librechat-2026-04-01-204252.yaml
- Env (redacted): migration-inventory/env-redacted-2026-04-01-204252.txt

## 1. Conversations
- Total conversation count: **0**
- 20 most recent conversations: **none**
- Tagged conversations: **0**
- Starred conversations: **0**
- Models/endpoints configured: **OpenRouter endpoint with 12 models**
  - deepseek/deepseek-chat
  - deepseek/deepseek-v3.2
  - deepseek/deepseek-r1
  - mistralai/mistral-large-2512
  - qwen/qwen3-235b-a22b
  - anthropic/claude-sonnet-4.6
  - openai/gpt-5
  - openai/o3
  - meta-llama/llama-4-maverick
  - nousresearch/hermes-4-70b
  - x-ai/grok-4
  - google/gemini-2.5-pro

## 2. Presets
- Total presets: **0**
- Preset list: **none**

## 3. Custom Endpoints
- Configured custom endpoints: **1**
- Endpoint: **OpenRouter**
  - Base URL: `https://openrouter.ai/api/v1`
  - Models listed: **12**
- OpenRouter/local/custom API notes:
  - OpenRouter: **yes**
  - Local model chat endpoint: **none configured**
  - Other custom chat APIs: **none configured**

## 4. Assistants / Agents
- Assistants: **0**
- Agents: **0**

## 5. Prompts Library
- Saved prompts: **0**

## 6. Files & Uploads
- Uploaded files: **0**

## 7. Configuration
- `librechat.yaml`: included below (full)
- `.env`: redacted file captured in snapshot file
- Custom fork/patch status:
  - Branch: `hydra-enterprise`
  - Commit: `d9604bc93`
  - Custom HYDRA code present under `api/hydra/`

## 8. Plugins / Tools
- Plugin auth records (`pluginauths`): **0**
- MCP servers in DB (`mcpservers`): **0**
- MCP servers in config (`librechat.yaml`): **2**
  - hydra_dashboard
  - hydra_rag
- Custom HYDRA tool modules present in repo: **yes** (`api/hydra/*.py`)

## 9. Users & Auth
- User accounts: **0**
- Auth method:
  - Local auth available by default
  - Social OAuth configured: **none** (`registration.socialLogins: []`)
  - LDAP config: **none found in active `librechat.yaml`**

## 10. Database
- Backend: **local MongoDB container (`mongo:7`)**
- DB name: `LibreChat`
- Approximate DB size:
  - `totalSize`: **1,261,568 bytes**
  - `dataSize`: **8,367 bytes**
  - `storageSize`: **225,280 bytes**
  - `indexSize`: **1,036,288 bytes**

---

## `librechat.yaml` (full)

```yaml
version: 1.3.6
cache: true

interface:
  customWelcome: "Welcome to HYDRA Enterprise."
  privacyPolicy:
    externalUrl: ""
  termsOfService:
    externalUrl: ""
  endpointsMenu: true
  modelSelect: true
  parameters: true
  sidePanel: true
  presets: true
  fileCitations: true

registration:
  socialLogins: []
  allowedDomains: []

endpoints:
  custom:
    - name: "OpenRouter"
      apiKey: "${OPENROUTER_API_KEY}"
      baseURL: "https://openrouter.ai/api/v1"
      models:
        default:
          - "deepseek/deepseek-chat"
          - "deepseek/deepseek-v3.2"
          - "deepseek/deepseek-r1"
          - "mistralai/mistral-large-2512"
          - "qwen/qwen3-235b-a22b"
          - "anthropic/claude-sonnet-4.6"
          - "openai/gpt-5"
          - "openai/o3"
          - "meta-llama/llama-4-maverick"
          - "nousresearch/hermes-4-70b"
          - "x-ai/grok-4"
          - "google/gemini-2.5-pro"
        fetch: false
      titleConvo: true
      titleModel: "deepseek/deepseek-chat"
      dropParams:
        - "user"
        - "stop"
      modelDisplayLabel: "HYDRA Models"

# LibreChat supports exactly one active provider for each speech direction.
speech:
  tts:
    elevenlabs:
      apiKey: "${ELEVENLABS_API_KEY}"
      model: "eleven_turbo_v2_5"
      voices:
        - "21m00Tcm4TlvDq8ikWAM"
  stt:
    openai:
      apiKey: "${OPENAI_API_KEY}"
      model: "whisper-1"
      url: "https://api.openai.com/v1/audio/transcriptions"
  speechTab:
    textToSpeech: true
    speechToText: true

mcpSettings:
  allowedDomains:
    - "localhost"
    - "127.0.0.1"
    - "host.docker.internal"

mcpServers:
  hydra_dashboard:
    type: sse
    url: "http://localhost:8091/api/mcp/sse"
    timeout: 30000
  hydra_rag:
    type: sse
    url: "http://localhost:8092/mcp/sse"
    timeout: 30000

actions:
  allowedDomains:
    - "openrouter.ai"
    - "localhost"
    - "127.0.0.1"
```
