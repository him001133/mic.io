# VoiceStudio Backend Docker Deployment

Docker configuration for deploying the VoiceStudio backend to various hosting services.

## Build

```bash
cd cloudflare/backend/docker
docker build -t voicestudio-backend:latest .
```

## Run Locally

```bash
docker run -p 3900:3900 \
  -e OMNIVOICE_PORT=3900 \
  -v $(pwd)/omnivoice_data:/app/omnivoice_data \
  voicestudio-backend:latest
```

## Deploy to HuggingFace Inference Endpoints

1. Build and push to HF Container Registry:

```bash
docker tag voicestudio-backend:latest \
  hf-ai-account.github.io/your-username/voicestudio-backend:latest
docker push hf-ai-account.github.io/your-username/voicestudio-backend:latest
```

2. Create Inference Endpoint in HF dashboard:
   - Select your container image
   - Choose GPU tier (T4, A10, etc.)
   - Configure persistent storage for models

3. Get the endpoint URL and set it as `BACKEND_ORIGIN` in the frontend Worker.

## Deploy to RunPod

1. Push image to Docker Hub or GHCR
2. Create a RunPod pod with the image
3. Configure GPU instance type
4. Get the pod URL and set as `BACKEND_ORIGIN`

## Deploy to Docker Hub (for any Docker service)

```bash
docker tag voicestudio-backend:latest \
  your-dockerhub-username/voicestudio-backend:latest
docker push your-dockerhub-username/voicestudio-backend:latest
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OMNIVOICE_PORT` | 3900 | API server port |
| `OMNIVOICE_DATA_DIR` | /app/omnivoice_data | Data directory for models, audio, settings |
| `OMNIVOICE_CACHE_DIR` | /app/.cache | HuggingFace cache directory |
| `HF_TOKEN` | (optional) | HuggingFace API token for private models |

## Storage

The backend needs persistent storage for:
- Downloaded ML models (several GB)
- Generated audio files
- User settings (SQLite)

Use Docker volumes or bind mounts to persist this data:

```bash
docker run -p 3900:3900 \
  -v voicestudio-models:/app/.cache/huggingface \
  -v voicestudio-audio:/app/omnivoice_data/audio \
  -v voicestudio-settings:/app/omnivoice_data/settings \
  voicestudio-backend:latest
```

## GPU Support

For GPU acceleration, use a GPU-enabled base image and ensure CUDA drivers are available:

```dockerfile
# NVIDIA CUDA base (for GPU instances)
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04
# ... then install Python and dependencies as above
```

Or use a cloud service that provides GPU Docker instances (RunPod, Lambda Labs, HF Inference Endpoints).
