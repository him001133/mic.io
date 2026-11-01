export interface Env {
  /** URL of the backend service that handles ML operations (TTS, ASR, dubbing).
   *  Can be:
   *  - An external service (HuggingFace Inference Endpoints, RunPod, GPU VM)
   *  - A Cloudflare Worker running the Python backend
   *  - A local dev server (for development)
   *
   *  If empty, API requests return 503 with a clear error message. */
  BACKEND_ORIGIN: string;
  /** Automatically-injected by Wrangler when using Workers Assets
   * (`assets` in wrangler.jsonc). Used to fetch and patch HTML responses
   * with the BACKEND_ORIGIN runtime variable. */
  __STATIC_CONTENT: {
    fetch: (request: Request) => Promise<Response>;
  };
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Static asset directories served by the Python backend in the web bundle.
    // In Cloudflare this is a Workers deployment, so we proxy those too.
    const proxiedPrefixes = ["/api/", "/audio/", "/voice_audio/", "/demo_audio/"];
    if (proxiedPrefixes.some((p) => url.pathname.startsWith(p))) {
      if (!env.BACKEND_ORIGIN) {
        return jsonError(
          503,
          "Backend origin is not configured. Set the BACKEND_ORIGIN Wrangler variable (e.g. https://api.example.com).",
        );
      }
      try {
        const backendUrl = new URL(url.pathname + url.search, env.BACKEND_ORIGIN);
        const headers = new Headers(request.headers);
        // Cloudflare-issued client IP is more useful to the backend than the Worker's IP.
        headers.set("CF-Connecting-IP", request.headers.get("CF-Connecting-IP") ?? "");
        // Let the backend know this is proxied traffic.
        headers.set("x-omnivoice-backend", "1");

        const method = request.method;
        if (method === "OPTIONS") {
          // Lean into the backend's own CORS handling by forwarding preflights,
          // but short-circuit when there is no backend so the UI gets a fast error.
          return fetch(backendUrl.toString(), {
            method,
            headers,
            redirect: "follow",
          });
        }

        return fetch(backendUrl.toString(), {
          method,
          headers,
          body:
            method === "GET" || method === "HEAD"
              ? undefined
              : request.body,
          redirect: "follow",
        });
      } catch (err) {
        return jsonError(502, `Failed to reach the backend: ${String(err)}`);
      }
    }

    // For HTML documents, inject BACKEND_ORIGIN so the frontend knows where
    // to send API requests (the Worker proxies /api/* to this origin).
    if (env.BACKEND_ORIGIN && (url.pathname === '/' || url.pathname.endsWith('.html'))) {
      // Try to fetch the asset from Workers Assets and patch it.
      const asset = env.__STATIC_CONTENT;
      if (asset) {
        try {
          const assetResponse = await asset.fetch(request);
          if (assetResponse.status === 200 &&
              assetResponse.headers.get('content-type')?.startsWith('text/html')) {
            const html = await assetResponse.text();
            const patched = html.replace(
              '<head>',
              `<head><script>window.__CLOUDFLARE_BACKEND_ORIGIN__=${JSON.stringify(env.BACKEND_ORIGIN)}</script>`,
              1,
            );
            return new Response(patched, {
              status: 200,
              headers: {
                'content-type': 'text/html; charset=utf-8',
                'cache-control': assetResponse.headers.get('cache-control') ?? 'no-cache',
              },
            });
          }
          // Non-HTML or not found: pass through to Workers Assets fallback.
          if (assetResponse.status !== 404) return assetResponse;
        } catch {
          // Fall through to 404 if asset fetch fails.
        }
      }
    }

    // Everything else (route navigation, static assets) is served by the
    // Workers Assets SPA fallback defined in wrangler.jsonc.
    return new Response(null, { status: 404 });
  },
} satisfies ExportedHandler<Env>;


function jsonError(status: number, message: string): Response {
  return new Response(JSON.stringify({ detail: message }), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}
