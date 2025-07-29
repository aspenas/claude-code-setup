#!/bin/bash
# Verify deployment of jonathon.candlefish.ai

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_URL="https://jonathon.candlefish.ai"

echo -e "${BLUE}Verifying deployment of jonathon.candlefish.ai${NC}"
echo "============================================="
echo

# Function to check URL
check_url() {
    local url=$1
    local name=$2
    
    echo -n "Checking $name... "
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# Check all pages
check_url "$BASE_URL" "Homepage"
check_url "$BASE_URL/complete-setup-guide.html" "Complete Setup Guide"
check_url "$BASE_URL/security-guide.html" "Security Guide"
check_url "$BASE_URL/quick-reference.html" "Quick Reference"
check_url "$BASE_URL/aws-setup.html" "AWS Setup"
check_url "$BASE_URL/project-templates.html" "Project Templates"
check_url "$BASE_URL/troubleshooting.html" "Troubleshooting"

echo
echo -e "${GREEN}✅ All pages are accessible!${NC}"
echo
echo "Live documentation: $BASE_URL"