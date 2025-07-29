#!/bin/bash
# Configure DNS for jonathon.candlefish.ai using Porkbun API
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
SUBDOMAIN="jonathon"
TARGET="zippy-macaron-c28bbf.netlify.app"
DOMAIN="candlefish.ai"

echo -e "${BLUE}Configuring DNS for jonathon.candlefish.ai using Porkbun API${NC}"
echo "======================================================="
echo

log "Retrieving Porkbun API credentials from AWS Secrets..."

# Get credentials from AWS
PORKBUN_CREDS=$(aws secretsmanager get-secret-value \
    --secret-id "porkbun/api-credentials" \
    --query SecretString \
    --output text) || error "Failed to retrieve Porkbun credentials"

API_KEY=$(echo "$PORKBUN_CREDS" | jq -r '.api_key')
SECRET_KEY=$(echo "$PORKBUN_CREDS" | jq -r '.secret_key')

if [ -z "$API_KEY" ] || [ -z "$SECRET_KEY" ]; then
    error "Missing API credentials"
fi

info "Credentials loaded successfully"

# Create DNS record using Porkbun API
create_dns_record() {
    log "Creating CNAME record: $SUBDOMAIN.$DOMAIN -> $TARGET"
    
    # Porkbun API endpoint
    API_URL="https://porkbun.com/api/json/v3/dns/create/$DOMAIN"
    
    # Create the record
    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"secretapikey\": \"$SECRET_KEY\",
            \"apikey\": \"$API_KEY\",
            \"name\": \"$SUBDOMAIN\",
            \"type\": \"CNAME\",
            \"content\": \"$TARGET\",
            \"ttl\": \"300\"
        }")
    
    # Debug: Show response
    echo "DEBUG: API Response: $RESPONSE"
    
    # Check response
    STATUS=$(echo "$RESPONSE" | jq -r '.status // "ERROR"' 2>/dev/null || echo "ERROR")
    
    if [ "$STATUS" = "SUCCESS" ]; then
        log "✅ DNS record created successfully!"
        return 0
    else
        # Check if record already exists
        if echo "$RESPONSE" | grep -q "already exists"; then
            log "Record already exists. Updating..."
            update_dns_record
        else
            MESSAGE=$(echo "$RESPONSE" | jq -r '.message // "Unknown error"')
            error "Failed to create DNS record: $MESSAGE"
        fi
    fi
}

# Update existing DNS record
update_dns_record() {
    log "Fetching existing DNS records..."
    
    # Get all DNS records
    RECORDS_URL="https://porkbun.com/api/json/v3/dns/retrieve/$DOMAIN"
    RECORDS=$(curl -s -X POST "$RECORDS_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"secretapikey\": \"$SECRET_KEY\",
            \"apikey\": \"$API_KEY\"
        }")
    
    # Find the record ID for our subdomain
    RECORD_ID=$(echo "$RECORDS" | jq -r ".records[] | select(.name == \"$SUBDOMAIN.$DOMAIN\") | .id // empty" | head -1)
    
    if [ -n "$RECORD_ID" ]; then
        log "Found existing record ID: $RECORD_ID. Updating..."
        
        # Update the record
        UPDATE_URL="https://porkbun.com/api/json/v3/dns/edit/$DOMAIN/$RECORD_ID"
        UPDATE_RESPONSE=$(curl -s -X POST "$UPDATE_URL" \
            -H "Content-Type: application/json" \
            -d "{
                \"secretapikey\": \"$SECRET_KEY\",
                \"apikey\": \"$API_KEY\",
                \"name\": \"$SUBDOMAIN\",
                \"type\": \"CNAME\",
                \"content\": \"$TARGET\",
                \"ttl\": \"300\"
            }")
        
        UPDATE_STATUS=$(echo "$UPDATE_RESPONSE" | jq -r '.status // "ERROR"')
        
        if [ "$UPDATE_STATUS" = "SUCCESS" ]; then
            log "✅ DNS record updated successfully!"
        else
            MESSAGE=$(echo "$UPDATE_RESPONSE" | jq -r '.message // "Unknown error"')
            error "Failed to update DNS record: $MESSAGE"
        fi
    else
        error "Could not find existing record to update"
    fi
}

# Main execution
main() {
    # Try to create the record
    create_dns_record
    
    echo
    echo -e "${GREEN}✅ DNS configuration complete!${NC}"
    echo
    echo "Your documentation will be available at:"
    echo "  https://jonathon.candlefish.ai"
    echo
    echo "DNS propagation usually takes 5-30 minutes."
    echo
    echo "Test with:"
    echo "  dig jonathon.candlefish.ai"
    echo "  curl -I https://jonathon.candlefish.ai"
    echo
    
    # Create verification script
    cat > verify-dns.sh << 'EOF'
#!/bin/bash
echo "Checking DNS propagation for jonathon.candlefish.ai..."
echo
echo "DNS Resolution:"
dig +short jonathon.candlefish.ai
echo
echo "Full DNS Query:"
dig jonathon.candlefish.ai
echo
echo "Testing HTTPS access:"
curl -I https://jonathon.candlefish.ai 2>&1 | head -n 5
EOF
    chmod +x verify-dns.sh
    
    echo "Run ./verify-dns.sh to check DNS propagation status"
}

# Run main
main