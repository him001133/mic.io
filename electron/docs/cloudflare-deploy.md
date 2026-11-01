# VoiceStudio Cloudflare Deployment

The VoiceStudio web app is deployed to Cloudflare as a Workers + Workers Assets project.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Cloudflare Edge                         │
├─────────────────────────────────────────────────────────────┤
│  Cloudflare Workers (Frontend)                             │
│  - Serves React SPA from Workers Assets                    │
│  - Proxies /api/*, /audio/*, /voice_audio/*, /demo_audio/* │
│  - Injects BACKEND_ORIGIN into HTML for the frontend       │
│  - SPA fallback for hash-routed navigation                 │
│  - File: electron/worker/index.ts                          │
├─────────────────────────────────────────────────────────────┤
│  Backend Service (External or Cloudflare Worker)           │
│  - Handles ML operations (TTS, ASR, dubbing, etc.)         │
│  - Can be deployed to:                                     │
│    * HuggingFace Inference Endpoints (GPU)                 │
│    * RunPod / Lambda Labs / GPU VM                         │
│    * Cloudflare Workers (lightweight, no GPU)              │
│    * Your own server                                       │
│  - Configured via BACKEND_ORIGIN environment variable       │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Deploy Frontend

```bash
cd electron
bun install
bun run build:cf
bun run deploy:cf
```

### 2. Configure Backend Origin

Set the `BACKEND_ORIGIN` environment variable in Cloudflare Pages:

**Settings → Environment Variables → Add:**

- **Key:** `BACKEND_ORIGIN`
- **Value:** Your backend service URL (e.g., `https://api.yourdomain.com`)
- **Environments:** Production + Preview (if needed)

### 3. Deploy Backend (Optional)

For a lightweight backend worker:

```bash
cd cloudflare/backend
wrangler deploy
```

For full ML functionality, deploy to an external GPU service and set `BACKEND_ORIGIN` to point to it.

## Local Development

```bash
# Terminal 1: Python backend (local)
cd backend
python -m uvicorn backend.main:app --host 127.0.0.1 --port 3900

# Terminal 2: Cloudflare preview
cd electron
BACKEND_ORIGIN=http://127.0.0.1:3900 bun run preview:cf
```

## Files

| File | Description |
|------|-------------|
| `electron/wrangler.jsonc` | Frontend Worker config |
| `electron/worker/index.ts` | Frontend Worker (SPA + API proxy) |
| `cloudflare/backend/worker/index.py` | Backend Worker (lightweight) |
| `cloudflare/backend/wrangler.toml` | Backend Worker config |
| `cloudflare/backend/docker/` | Docker configs for external hosting |
| `cloudflare/deploy.sh` | Deployment script |

## Environment Variables

### Frontend Worker

| Variable | Required | Description |
|----------|----------|-------------|
| `BACKEND_ORIGIN` | Yes | URL of the backend service. If empty, API returns 503. |

### Backend Worker

| Variable | Required | Description |
|----------|----------|-------------|
| `BACKEND_ORIGIN` | No | URL of external ML backend (for hybrid deployments) |

## Backend Options

### Option A: Cloudflare Workers Python (Lightweight)

Best for: Basic API routes, health checks, auth handling

```bash
cd cloudflare/backend
wrangler deploy
```

Limitations:
- No GPU access
- Execution time limits (~10s CPU time)
- Not suitable for real-time TTS generation

### Option B: External GPU Service (Full ML)

Best for: Full VoiceStudio functionality (TTS, ASR, dubbing)

Services:
- **HuggingFace Inference Endpoints**: Managed GPU, starting at ~$0.60/hr
- **RunPod**: GPU cloud, starting at ~$0.20/hr
- **Lambda Labs**: GPU instances, starting at ~$0.50/hr
- **Your own server**: Full control

1. Build the Docker image: `cd cloudflare/backend/docker && docker build -t voicestudio-backend .`
2. Deploy to your chosen service
3. Set `BACKEND_ORIGIN` to the service URL

### Option C: Local + Tunnel (Development)

Keep the backend running locally and expose via:

- **Cloudflare Tunnel**: `cloudflared tunnel --url http://localhost:3900`
- **Tailscale**: Set up Tailscale and use the tailnet URL
- **ngrok**: `ngrok http 3900`

## WebSocket Support

The backend uses WebSockets for real-time events (`/ws/events`, `/ws/transcribe`, `/ws/tts`).

- **Cloudflare Workers**: WebSocket support is available but has limitations
- **External services**: Full WebSocket support

For production, use an external backend service for reliable WebSocket handling.

## CORS and Security

The Worker forwards requests to the backend, including:
- `CF-Connecting-IP` header (client's real IP)
- `x-omnivoice-backend: 1` header (marks proxied requests)

The backend should:
- Allow CORS from your Cloudflare domain
- Validate the `x-omnivoice-backend` header if needed
- Handle authentication (API keys, sessions)

## Troubleshooting

### 503 Backend Not Configured

If you see `{"detail": "Backend origin is not configured..."}`:

1. Set `BACKEND_ORIGIN` in Cloudflare Pages environment variables
2. Redeploy or wait for env vars to propagate (can take a few minutes)

### 502 Backend Unreachable

If you see `{"detail": "Failed to reach the backend..."}`:

1. Check that your backend service is running
2. Verify the `BACKEND_ORIGIN` URL is correct
3. Check CORS settings on the backend
4. Check network connectivity from Cloudflare to your backend

### Audio/File Uploads Not Working

For large file uploads:
- Use a dedicated storage service (R2, S3) for audio files
- Configure the backend to accept uploads from Cloudflare IPs
- Consider streaming uploads for large files

## Resources

- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Cloudflare Pages Docs](https://developers.cloudflare.com/pages/)
- [HuggingFace Inference Endpoints](https://huggingface.co/inference-endpoints)
- [RunPod](https://runpod.io/)
- [Lambda Labs](https://lambdalabs.com/)
