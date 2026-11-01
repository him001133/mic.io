"""
VoiceStudio Backend Worker for Cloudflare Workers (Python runtime).

This is a minimal Python FastAPI-compatible worker that runs on Cloudflare Workers.
It handles the API routes that don't require heavy ML computation.

For full ML functionality (TTS, ASR, etc.), use an external service
and configure BACKEND_ORIGIN in the frontend Worker.
"""

import json
from typing import Any
from urllib.parse import parse_qs

# Minimal request handler for Cloudflare Workers Python runtime
# This provides a basic API surface; heavy ML operations are proxied to
# an external backend configured via the frontend Worker's BACKEND_ORIGIN.


async def on_request(request):
    """Handle incoming requests."""
    url = str(request.url)
    method = request.method

    # Health check
    if url.path.endswith("/health"):
        return Response(
            json.dumps({"status": "ok", "service": "voicestudio-backend"}),
            headers={"Content-Type": "application/json"},
        )

    # Info endpoint
    if url.path.endswith("/api/system/info"):
        return Response(
            json.dumps({
                "ok": True,
                "version": "0.5.7",
                "product": "VoiceStudio",
            }),
            headers={"Content-Type": "application/json"},
        )

    # CORS preflight
    if method == "OPTIONS":
        return Response(
            "",
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization, X-OmniVoice-Pin, X-VoiceStudio-CSRF",
                "Access-Control-Max-Age": "86400",
            },
        )

    # Proxy to external backend for all other requests
    # In production, this would forward to the actual backend service
    backend_origin = request.headers.get("CF-Connecting-IP", "") or ""

    return Response(
        json.dumps({
            "detail": "Backend routes are proxied to the external service. "
                      "Configure the external backend and set BACKEND_ORIGIN in the frontend Worker.",
            }),
        status=503,
        headers={
            "Content-Type": "application/json",
            "X-Backend-Proxied": "true",
        },
    )


class Response:
    """Minimal Response class for Cloudflare Workers Python runtime."""

    def __init__(self, body: str, status: int = 200, headers: dict = None):
        self.body = body
        self.status = status
        self.headers = headers or {}

    async def __call__(self, request):
        from cloudflare_workers import Response as WFResponse
        return WFResponse(
            self.body,
            status=self.status,
            headers=self.headers,
        )


# Export for Cloudflare Workers
async def handle_request(request):
    return await on_request(request)
