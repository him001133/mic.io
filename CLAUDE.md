# CLAUDE.md — Custom VoiceStudio & Audio Tools Web App

## 1. Project Identity & Core Philosophy
This project is a customized distribution of `debpalash/VoiceStudio` (`omnivoice-studio-monorepo`), combining **local-first AI speech synthesis/cloning/dubbing** with a **full-featured Audio Production & Utility Suite**.

- **100% Free & Local-First:** Never introduce mandatory paid cloud APIs or external telemetry. All processing must run either in the browser (Web Audio API / WebAssembly) or on the local Python FastAPI backend (CPU / CUDA / Vulkan / MPS).
- **Web-First Accessibility:** While the codebase uses `electron/` as its frontend workspace package, every feature must work seamlessly in standalone Web mode (`bun run dev:web` / `bun run build:web`) via standard HTTP/WebSocket calls without hard crashing when `window.electron` IPC bridges are absent.
- **Seamless Audio Routing:** Every utility tool (Trimmer, Noise Cleaner, Normalizer, Stem Splitter) must allow one-click forwarding of its output audio directly into the AI Voice Cloning, Voice Design, or Video Dubbing pipelines.

---

## 2. Monorepo Architecture (`omnivoice-studio-monorepo`)

```text
├── package.json                 # Root Bun monorepo config & single version source of truth
├── scripts/
│   ├── setup-api.mjs            # Bootstraps local Python environment & dependencies
│   ├── dev-backend.mjs          # Launches FastAPI backend server
│   └── clear-dev-ports.mjs      # Port management for web + API dev servers
├── backend/                     # Python FastAPI Backend (TTS, ASR, DSP, Model Manager)
│   ├── core/                    # Version, hardware/GPU detection, config, mark_synthetic
│   ├── routers/                 # FastAPI route handlers (cloning, dubbing, transcription, audio_tools)
│   ├── services/                # Engine adapters (OmniVoice, CosyVoice, Whisper, FFmpeg DSP)
│   └── models/                  # Pydantic schemas & model inventory manifests
├── electron/                    # Frontend Workspace (React + TypeScript + Vite)
│   ├── src/
│   │   ├── pages/               # Workspace views (Voice Cloning, Dubbing, Audio Tools, Studio)
│   │   ├── components/          # Shared UI (VoiceSelector, custom Select, Waveform, Modals)
│   │   ├── store/               # Client state & job queue management
│   │   ├── services/            # API client & Web Audio processing helpers
│   │   └── locales/             # i18n translation JSON catalogs
└── tests/                       # Backend (pytest) and Frontend (node --test / Playwright) suites
