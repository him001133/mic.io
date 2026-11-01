# VoiceStudio Cloudflare Deployment

This directory contains the Cloudflare deployment configuration for VoiceStudio.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Cloudflare Edge                         │
├─────────────────────────────────────────────────────────────┤
│  Cloudflare Workers (Frontend)                             │
│  - Serves React SPA from Workers Assets                    │
│  - Proxies /api/* to backend                               │
│  - Injects BACKEND_ORIGIN into HTML                        │
│  - Location: electron/worker/index.ts                      │
├─────────────────────────────────────────────────────────────┤
│  Cloudflare Workers (Backend - Lightweight)                │
│  - Handles basic API routes (health, info)                 │
│  - Proxies ML requests to external service                 │
│  - Location: cloudflare/backend/worker/index.py            │
├─────────────────────────────────────────────────────────────┤
│  External Backend Service (Recommended for ML workloads)   │
│  - HuggingFace Inference Endpoints                         │
│  - RunPod / Lambda Labs / GPU VM                           │
│  - Handles TTS, ASR, dubbing, etc.                         │
│  - Configured via BACKEND_ORIGIN                           │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Deploy Frontend (already configured)

```bash
cd electron
bun install
bun run build:cf
bun run deploy:cf
```

### 2. Set Backend Origin

In Cloudflare Pages settings, set the environment variable:

```
BACKEND_ORIGIN=https://your-backend-service-url
```

For local development:

```bash
cd electron
BACKEND_ORIGIN=http://127.0.0.1:3900 bun run preview:cf
```

### 3. Deploy Backend Worker (optional)

```bash
cd cloudflare/backend
npm install -g wrangler
wrangler deploy
```

## Backend Options

### Option A: External Service (Recommended)

For full ML functionality, deploy the Python backend to:

- **HuggingFace Inference Endpoints**: GPU-enabled, managed
- **RunPod / Lambda Labs**: GPU cloud VMs
- **AWS/GCP/Azure**: Full control

Update `BACKEND_ORIGIN` to point to your service.

### Option B: Cloudflare Workers Python Runtime

For lightweight API handling without ML:

```bash
cd cloudflare/backend
wrangler deploy
```

Limitations:
- No GPU access
- Execution time limits
- Model weights must be downloaded at runtime (slow)

### Option C: Hybrid

- Cloudflare Worker handles auth, routing, caching
- External service handles ML generation
- Worker proxies between them

## Environment Variables

### Frontend Worker (electron/wrangler.jsonc)

| Variable | Description |
|----------|-------------|
| `BACKEND_ORIGIN` | URL of the backend service (required) |

### Backend Worker (cloudflare/backend/wrangler.toml)

| Variable | Description |
|----------|-------------|
| `BACKEND_ORIGIN` | URL of external ML backend (if hybrid) |

## Local Development

```bash
# Terminal 1: Python backend (local)
cd backend
python -m uvicorn backend.main:app --host 127.0.0.1 --port 3900

# Terminal 2: Cloudflare preview
cd electron
BACKEND_ORIGIN=http://127.0.0.1:3900 bun run preview:cf
```

## Documentation

- Frontend deployment: `electron/docs/cloudflare-deploy.md`
- Backend architecture: `backend/README.md`
- Model configuration: `backend/config/models.yaml`
