# VoiceStudio Backend - Docker image for Cloudflare Workers + External Service
# 
# This Dockerfile creates a container for the Python FastAPI backend.
# Use this with:
# - HuggingFace Inference Endpoints
# - RunPod / Lambda Labs / GPU cloud
# - AWS ECS / Google Cloud Run / Azure Container Instances
# - Any Docker-compatible hosting

FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy backend code
COPY . .

# Install Python dependencies
# Using pip for compatibility; uv is faster but pip is more universal
RUN pip install --no-cache-dir -e .

# Set environment variables
ENV OMNIVOICE_PORT=3900
ENV PYTHONUNBUFFERED=1

# Expose the API port
EXPOSE 3900

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3900/health || exit 1

# Run the backend
CMD ["python", "-m", "uvicorn", "backend.main:app", \
     "--host", "0.0.0.0", \
     "--port", "3900"]
