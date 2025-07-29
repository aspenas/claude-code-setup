#!/bin/bash
# Automatically configure DNS for jonathon.candlefish.ai in Cloudflare
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
DOMAIN="candlefish.ai"
SUBDOMAIN="jonathon"
TARGET="zippy-macaron-c28bbf.netlify.app"

echo -e "${BLUE}Auto-configuring DNS for jonathon.candlefish.ai${NC}"
echo "=============================================="
echo

# Try to get Cloudflare credentials from AWS Secrets
get_cloudflare_creds() {
    log "Checking for Cloudflare credentials in AWS Secrets..."
    
    # Try to get Cloudflare API token
    CLOUDFLARE_TOKEN=$(aws secretsmanager get-secret-value \
        --secret-id "cloudflare-api-token" \
        --query SecretString \
        --output text 2>/dev/null) || \
    CLOUDFLARE_TOKEN=$(aws secretsmanager get-secret-value \
        --secret-id "CLOUDFLARE_API_TOKEN" \
        --query SecretString \
        --output text 2>/dev/null) || \
    CLOUDFLARE_TOKEN=""
    
    # Try to get Zone ID
    CLOUDFLARE_ZONE_ID=$(aws secretsmanager get-secret-value \
        --secret-id "cloudflare-zone-id" \
        --query SecretString \
        --output text 2>/dev/null) || \
    CLOUDFLARE_ZONE_ID=""
    
    if [ -n "$CLOUDFLARE_TOKEN" ]; then
        info "Cloudflare API token found"
        return 0
    else
        return 1
    fi
}

# Get Zone ID if not provided
get_zone_id() {
    if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
        log "Fetching Zone ID for $DOMAIN..."
        
        ZONE_RESPONSE=$(curl -s -X GET \
            -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN")
        
        CLOUDFLARE_ZONE_ID=$(echo "$ZONE_RESPONSE" | jq -r '.result[0].id // empty')
        
        if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
            error "Could not find zone ID for $DOMAIN"
        fi
        
        info "Zone ID: $CLOUDFLARE_ZONE_ID"
    fi
}

# Create CNAME record
create_cname_record() {
    log "Creating CNAME record: $SUBDOMAIN -> $TARGET"
    
    # Check if record already exists
    EXISTING=$(curl -s -X GET \
        -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$SUBDOMAIN.$DOMAIN")
    
    RECORD_ID=$(echo "$EXISTING" | jq -r '.result[0].id // empty')
    
    if [ -n "$RECORD_ID" ]; then
        log "Record already exists. Updating..."
        
        # Update existing record
        RESPONSE=$(curl -s -X PUT \
            -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"type\": \"CNAME\",
                \"name\": \"$SUBDOMAIN\",
                \"content\": \"$TARGET\",
                \"ttl\": 300,
                \"proxied\": false
            }" \
            "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$RECORD_ID")
    else
        log "Creating new record..."
        
        # Create new record
        RESPONSE=$(curl -s -X POST \
            -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"type\": \"CNAME\",
                \"name\": \"$SUBDOMAIN\",
                \"content\": \"$TARGET\",
                \"ttl\": 300,
                \"proxied\": false
            }" \
            "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records")
    fi
    
    # Check response
    if echo "$RESPONSE" | jq -e '.success' > /dev/null; then
        log "✅ DNS record configured successfully!"
    else
        error "Failed to create DNS record: $(echo "$RESPONSE" | jq -r '.errors')"
    fi
}

# Manual instructions
show_manual_instructions() {
    echo -e "${YELLOW}Manual DNS Configuration Required${NC}"
    echo "================================="
    echo
    echo "Add this CNAME record to your DNS provider:"
    echo
    echo "  Type: CNAME"
    echo "  Name: $SUBDOMAIN"
    echo "  Value: $TARGET"
    echo "  TTL: 300 (5 minutes)"
    echo "  Proxy: Disabled (DNS only)"
    echo
    echo "For Cloudflare:"
    echo "1. Go to: https://dash.cloudflare.com"
    echo "2. Select your domain: $DOMAIN"
    echo "3. Go to DNS settings"
    echo "4. Add the CNAME record above"
    echo "5. Make sure proxy is OFF (gray cloud)"
}

# Main execution
main() {
    if get_cloudflare_creds; then
        get_zone_id
        create_cname_record
        
        echo
        echo -e "${GREEN}✅ DNS configuration complete!${NC}"
        echo
        echo "Your documentation will be available at:"
        echo "  https://jonathon.candlefish.ai"
        echo
        echo "DNS propagation usually takes 5-30 minutes."
        echo
        echo "Test with: dig jonathon.candlefish.ai"
    else
        info "Cloudflare credentials not found in AWS Secrets"
        echo
        show_manual_instructions
    fi
}

# Run main
main