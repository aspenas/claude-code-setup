#!/bin/bash
# Deploy Documentation to Netlify
# Author: Patrick Smith (patrick@candlefish.ai)

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Configuration
DOCS_DIR="$HOME/candlefish-ai/projects/jonathon/docs-site"
SITE_NAME="candlefish-claude-docs"
CUSTOM_DOMAIN="docs.candlefish.ai"

# Check if Netlify CLI is installed
check_netlify() {
    if ! command -v netlify &> /dev/null; then
        log "Installing Netlify CLI..."
        npm install -g netlify-cli
    else
        info "Netlify CLI is already installed"
    fi
}

# Deploy to Netlify
deploy_site() {
    log "Deploying documentation to Netlify..."
    
    cd "$DOCS_DIR"
    
    # Check if we're already linked to a site
    if [ -f ".netlify/state.json" ]; then
        info "Site already linked to Netlify"
    else
        log "Creating new Netlify site..."
        netlify init --manual
    fi
    
    # Deploy to production
    log "Deploying to production..."
    netlify deploy --prod --dir . --message "Documentation update $(date)"
    
    # Get the site URL
    SITE_URL=$(netlify status --json | jq -r '.site_url' || echo "https://$SITE_NAME.netlify.app")
    
    info "Site deployed to: $SITE_URL"
}

# Configure custom domain
configure_domain() {
    log "Configuring custom domain..."
    
    # Add custom domain
    netlify domains:add "$CUSTOM_DOMAIN" 2>/dev/null || warning "Domain already configured"
    
    info "Custom domain configured: https://$CUSTOM_DOMAIN"
    info "Please ensure your DNS points to Netlify:"
    info "  - Add CNAME record: docs -> $SITE_NAME.netlify.app"
    info "  - Or use Netlify DNS for automatic configuration"
}

# Main execution
main() {
    echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│   Candlefish AI Documentation Deploy   │${NC}"
    echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
    echo
    
    # Check prerequisites
    check_netlify
    
    # Ensure docs are built
    if [ ! -f "$DOCS_DIR/index.html" ]; then
        error "Documentation not found. Please run convert-docs-to-html.js first."
    fi
    
    # Deploy
    deploy_site
    
    # Configure domain
    configure_domain
    
    echo
    echo -e "${GREEN}✅ Deployment complete!${NC}"
    echo
    echo "Next steps:"
    echo "1. Visit $SITE_URL to verify deployment"
    echo "2. Configure DNS for $CUSTOM_DOMAIN"
    echo "3. Enable HTTPS in Netlify settings (automatic)"
    echo
    echo "Documentation is now live!"
}

# Run main function
main "$@"