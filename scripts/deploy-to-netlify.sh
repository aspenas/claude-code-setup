#!/bin/bash
# Deploy updated documentation to Netlify
# Author: Patrick Smith (patrick@candlefish.ai)

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Configuration
SITE_ID="zippy-macaron-c28bbf"
ZIP_FILE="docs-site-updated.zip"

echo -e "${BLUE}Deploying updated documentation to Netlify${NC}"
echo "=========================================="
echo

log "Loading Netlify API credentials from AWS Secrets..."

# Get Netlify token from AWS Secrets
NETLIFY_AUTH_TOKEN=$(aws secretsmanager get-secret-value \
    --secret-id "netlify-api-token" \
    --query SecretString \
    --output text 2>/dev/null) || error "Failed to retrieve Netlify token"

if [ -z "$NETLIFY_AUTH_TOKEN" ]; then
    error "NETLIFY_AUTH_TOKEN is empty"
fi

info "Netlify API token loaded successfully"

# Deploy using Netlify API
deploy_site() {
    log "Deploying $ZIP_FILE to site $SITE_ID..."
    
    # Create deployment
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
        -H "Content-Type: application/zip" \
        --data-binary "@$ZIP_FILE" \
        "https://api.netlify.com/api/v1/sites/$SITE_ID/deploys")
    
    # Check if successful
    DEPLOY_ID=$(echo "$RESPONSE" | jq -r '.id // empty')
    
    if [ -n "$DEPLOY_ID" ]; then
        log "✅ Deployment created successfully!"
        info "Deploy ID: $DEPLOY_ID"
        
        # Get deployment status
        STATE=$(echo "$RESPONSE" | jq -r '.state // "unknown"')
        DEPLOY_URL=$(echo "$RESPONSE" | jq -r '.deploy_ssl_url // empty')
        
        info "Deploy State: $STATE"
        info "Deploy URL: $DEPLOY_URL"
        
        return 0
    else
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.message // "Unknown error"')
        error "Failed to deploy: $ERROR_MSG"
    fi
}

# Check deployment status
check_deploy_status() {
    local deploy_id=$1
    log "Checking deployment status..."
    
    for i in {1..30}; do
        RESPONSE=$(curl -s -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
            "https://api.netlify.com/api/v1/deploys/$deploy_id")
        
        STATE=$(echo "$RESPONSE" | jq -r '.state // "unknown"')
        
        case "$STATE" in
            "ready")
                log "✅ Deployment ready!"
                return 0
                ;;
            "error")
                ERROR_LOG=$(echo "$RESPONSE" | jq -r '.error_message // "Unknown error"')
                error "Deployment failed: $ERROR_LOG"
                ;;
            *)
                info "Deployment state: $STATE (checking again in 2s...)"
                sleep 2
                ;;
        esac
    done
    
    error "Deployment timed out"
}

# Main execution
main() {
    # Check if zip file exists
    if [ ! -f "$ZIP_FILE" ]; then
        error "Zip file not found: $ZIP_FILE"
    fi
    
    # Deploy the site
    RESPONSE=$(deploy_site)
    DEPLOY_ID=$(echo "$RESPONSE" | jq -r '.id // empty' 2>/dev/null || echo "")
    
    if [ -n "$DEPLOY_ID" ]; then
        # Check deployment status
        check_deploy_status "$DEPLOY_ID"
    fi
    
    echo
    echo -e "${GREEN}✅ Deployment complete!${NC}"
    echo
    echo "Your documentation is available at:"
    echo "  https://jonathon.candlefish.ai (after DNS propagation)"
    echo "  https://$SITE_ID.netlify.app (available now)"
    echo
    echo "GitHub repository:"
    echo "  https://github.com/aspenas/claude-code-setup"
}

# Run main
main