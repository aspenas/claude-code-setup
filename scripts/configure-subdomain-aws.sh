#!/bin/bash
# Configure jonathon.candlefish.ai using Netlify API token from AWS Secrets
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

echo -e "${BLUE}Configuring jonathon.candlefish.ai via AWS Secrets${NC}"
echo "=================================================="
echo

# Try to get Netlify token from AWS Secrets
get_netlify_token() {
    log "Attempting to retrieve Netlify API token from AWS Secrets..."
    
    # Common secret names to try
    local secret_names=(
        "netlify/api-token"
        "netlify-api-token"
        "NETLIFY_AUTH_TOKEN"
        "netlify/auth-token"
        "candlefish/netlify-token"
    )
    
    for secret in "${secret_names[@]}"; do
        info "Trying secret: $secret"
        if TOKEN=$(aws secretsmanager get-secret-value --secret-id "$secret" --query SecretString --output text 2>/dev/null); then
            log "Found Netlify token in AWS Secrets!"
            export NETLIFY_AUTH_TOKEN="$TOKEN"
            return 0
        fi
    done
    
    # If not found, check for environment variable
    if [ -n "${NETLIFY_AUTH_TOKEN:-}" ]; then
        log "Using NETLIFY_AUTH_TOKEN from environment"
        return 0
    fi
    
    error "Could not find Netlify API token in AWS Secrets or environment"
}

# Quick method using Netlify CLI
configure_with_cli() {
    log "Configuring custom domain using Netlify CLI..."
    
    cd ~/candlefish-ai/projects/jonathon/docs-site
    
    # Link to the existing site
    netlify link --id zippy-macaron-c28bbf
    
    # Add custom domain
    netlify domains:add jonathon.candlefish.ai
    
    log "Custom domain added!"
}

# Main execution
main() {
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &>/dev/null; then
        error "AWS CLI not configured. Please run 'aws configure' first."
    fi
    
    # Try to get Netlify token
    if get_netlify_token; then
        info "Netlify token loaded successfully"
        
        # Run the Node.js configuration script
        node ~/candlefish-ai/projects/jonathon/scripts/netlify-api-config.js
    else
        warning "Falling back to CLI method..."
        configure_with_cli
    fi
    
    echo
    echo -e "${GREEN}Next Steps:${NC}"
    echo "1. Configure DNS for jonathon.candlefish.ai"
    echo "2. Add CNAME: jonathon -> zippy-macaron-c28bbf.netlify.app"
    echo "3. Wait for propagation (5-30 minutes)"
    echo "4. Access at: https://jonathon.candlefish.ai"
}

# List AWS Secrets (helper function)
list_secrets() {
    log "Listing available secrets in AWS..."
    aws secretsmanager list-secrets --query "SecretList[?contains(Name, 'netlify') || contains(Name, 'NETLIFY')].[Name]" --output table
}

# Parse arguments
case "${1:-}" in
    "list")
        list_secrets
        ;;
    *)
        main
        ;;
esac