#!/bin/bash
# Automatically configure jonathon.candlefish.ai using Netlify API
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
CUSTOM_DOMAIN="jonathon.candlefish.ai"

echo -e "${BLUE}Auto-configuring jonathon.candlefish.ai${NC}"
echo "========================================"
echo

log "Loading Netlify API credentials from AWS Secrets..."

# Get Netlify token directly from AWS Secrets
NETLIFY_AUTH_TOKEN=$(aws secretsmanager get-secret-value \
    --secret-id "netlify-api-token" \
    --query SecretString \
    --output text 2>/dev/null) || {
    error "Failed to retrieve netlify-api-token from AWS Secrets"
}

# Check if we have the Netlify token
if [ -z "${NETLIFY_AUTH_TOKEN:-}" ]; then
    error "NETLIFY_AUTH_TOKEN is empty"
fi

info "Netlify API token loaded successfully"

# Add custom domain using curl
add_custom_domain() {
    log "Adding custom domain: $CUSTOM_DOMAIN to site: $SITE_ID"
    
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"domain\": \"$CUSTOM_DOMAIN\"}" \
        "https://api.netlify.com/api/v1/sites/$SITE_ID/domains")
    
    # Check if successful or already exists
    if echo "$RESPONSE" | grep -q "error"; then
        if echo "$RESPONSE" | grep -q "already exists"; then
            warning "Domain already configured"
        else
            error "Failed to add domain: $RESPONSE"
        fi
    else
        log "✅ Custom domain added successfully!"
    fi
}

# Get site details
get_site_info() {
    log "Fetching site information..."
    
    SITE_INFO=$(curl -s -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
        "https://api.netlify.com/api/v1/sites/$SITE_ID")
    
    if echo "$SITE_INFO" | grep -q "error"; then
        error "Failed to get site info: $SITE_INFO"
    fi
    
    # Extract relevant info
    SITE_NAME=$(echo "$SITE_INFO" | jq -r '.name // "N/A"')
    SITE_URL=$(echo "$SITE_INFO" | jq -r '.url // "N/A"')
    SSL_URL=$(echo "$SITE_INFO" | jq -r '.ssl_url // "N/A"')
    
    info "Site Name: $SITE_NAME"
    info "Current URL: $SSL_URL"
}

# Provision SSL certificate
provision_ssl() {
    log "Provisioning SSL certificate for $CUSTOM_DOMAIN..."
    
    curl -s -X POST \
        -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
        "https://api.netlify.com/api/v1/sites/$SITE_ID/ssl" > /dev/null
    
    info "SSL provisioning initiated"
}

# Main execution
main() {
    # Get current site info
    get_site_info
    
    # Add custom domain
    add_custom_domain
    
    # Provision SSL
    provision_ssl
    
    echo
    echo -e "${GREEN}✅ Configuration complete!${NC}"
    echo
    echo -e "${YELLOW}DNS Configuration Required:${NC}"
    echo "Add this CNAME record to your DNS provider:"
    echo
    echo "  Type: CNAME"
    echo "  Name: jonathon"
    echo "  Value: $SITE_ID.netlify.app"
    echo "  TTL: 300"
    echo
    echo "For Cloudflare: Set proxy status to 'DNS only' (gray cloud)"
    echo
    echo -e "${BLUE}Your documentation will be available at:${NC}"
    echo "  https://jonathon.candlefish.ai (after DNS propagation)"
    echo "  $SSL_URL (available now)"
    echo
    
    # Create verification script
    cat > verify-subdomain.sh << 'EOF'
#!/bin/bash
echo "Checking DNS propagation..."
dig +short jonathon.candlefish.ai
echo
echo "Testing HTTPS access..."
curl -I https://jonathon.candlefish.ai 2>/dev/null | head -n 1
EOF
    chmod +x verify-subdomain.sh
    
    echo "Run ./verify-subdomain.sh to check DNS propagation"
}

# Run main function
main