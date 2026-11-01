#!/bin/bash
# VoiceStudio Cloudflare Deployment Script
# 
# Deploys both frontend and backend to Cloudflare.
# 
# Usage:
#   ./cloudflare/deploy.sh [frontend|backend|all] [options]
#
# Examples:
#   ./cloudflare/deploy.sh frontend          # Deploy only frontend
#   ./cloudflare/deploy.sh backend           # Deploy only backend worker
#   ./cloudflare/deploy.sh all               # Deploy both
#   ./cloudflare/deploy.sh all --prod       # Deploy to production

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

FRONTEND_DIR="$PROJECT_ROOT/electron"
BACKEND_DIR="$SCRIPT_DIR/backend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

deploy_frontend() {
    log_info "Deploying frontend to Cloudflare Pages..."
    
    cd "$FRONTEND_DIR"
    
    # Check if wrangler is installed
    if ! command -v wrangler &> /dev/null; then
        log_warn "wrangler not found, installing..."
        npm install -g wrangler
    fi
    
    # Build frontend
    log_info "Building frontend..."
    bun run build:cf
    
    # Deploy
    log_info "Deploying to Cloudflare Pages..."
    bun run deploy:cf
    
    log_info "Frontend deployed successfully!"
}

deploy_backend() {
    log_info "Deploying backend worker to Cloudflare..."
    
    cd "$BACKEND_DIR"
    
    # Check if wrangler is installed
    if ! command -v wrangler &> /dev/null; then
        log_warn "wrangler not found, installing..."
        npm install -g wrangler
    fi
    
    # Deploy backend worker
    log_info "Deploying backend worker..."
    wrangler deploy
    
    log_info "Backend worker deployed successfully!"
    log_info "Configure BACKEND_ORIGIN in the frontend Worker to point to this backend."
}

deploy_all() {
    log_info "Deploying VoiceStudio to Cloudflare..."
    
    # Deploy frontend first
    deploy_frontend
    
    # Then deploy backend
    deploy_backend
    
    log_info ""
    log_info "========================================="
    log_info "Deployment complete!"
    log_info "========================================="
    log_info ""
    log_info "Next steps:"
    log_info "1. Set BACKEND_ORIGIN in Cloudflare Pages environment variables"
    log_info "   to point to your backend service URL"
    log_info "2. For local testing: BACKEND_ORIGIN=http://127.0.0.1:3900 bun run preview:cf"
    log_info "3. For production: Configure your external backend service"
    log_info ""
}

show_help() {
    cat << EOF
VoiceStudio Cloudflare Deployment Script

Usage: $0 [command] [options]

Commands:
  frontend    Deploy only the frontend (React SPA + Worker proxy)
  backend     Deploy only the backend worker
  all         Deploy both frontend and backend (default)
  help        Show this help message

Options:
  --prod      Deploy to production environment
  --dry-run   Show what would be deployed without actually deploying

Environment Variables:
  BACKEND_ORIGIN    URL of the backend service (set in Cloudflare Pages settings)

Examples:
  $0 frontend          Deploy frontend only
  $0 backend           Deploy backend worker only
  $0 all               Deploy everything
  $0 all --prod        Deploy to production

EOF
}

# Main
case "${1:-all}" in
    frontend)
        deploy_frontend
        ;;
    backend)
        deploy_backend
        ;;
    all)
        deploy_all
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
