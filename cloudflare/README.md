# Cloudflare Backend Deployment

The VoiceStudio backend (Python FastAPI) can be deployed to Cloudflare using one of these approaches:

## Option 1: Cloudflare Workers with Python (Beta)

Cloudflare now supports Python in Workers. This is the purest "backend on Cloudflare" option.

### Setup

1. Create a `cloudflare/backend/` directory with your Python FastAPI app
2. Use `wrangler.toml` with `compatibility_date` and Python support
3. Deploy with `wrangler deploy`

### Limitations

- Workers have execution time limits (CPU time, not wall time)
- Long-running TTS generation may hit timeouts
- Model weights need to be downloaded to ephemeral storage or R2
- WebSocket support is available but has limitations

## Option 2: Cloudflare Workers + External Service

More practical for a heavy ML backend:

1. **Frontend + API proxy**: Cloudflare Workers (already set up in `electron/`)
2. **Backend**: Run on a service that supports long-running Python + GPU:
   - HuggingFace Inference Endpoints
   - RunPod
   - Lambda Labs
   - AWS/GCP/Azure VM with GPU

The Worker in `electron/worker/index.ts` proxies `/api/*` requests to the backend origin configured via `BACKEND_ORIGIN`.

## Configuration

Set `BACKEND_ORIGIN` in Cloudflare Pages environment variables to point to your backend:

```
BACKEND_ORIGIN=https://your-backend.your-subdomain.workers.dev
```

Or for an external service:

```
BACKEND_ORIGIN=https://api.yourdomain.com
```

## Local Development

```bash
cd electron
BACKEND_ORIGIN=http://127.0.0.1:3900 bun run preview:cf
```

## Deployment Scripts

See `cloudflare/backend/` for deployment configurations.

---

## Files Structure

```
cloudflare/
├── backend/          # Python backend deployment configs
│   ├── worker/       # If using Workers Python runtime
│   └── docker/       # Docker configs for external hosting
└── frontend/         # Already configured in electron/
```
