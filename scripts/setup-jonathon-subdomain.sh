#!/bin/bash
# Setup jonathon.candlefish.ai subdomain on Candlefish Grotto Netlify
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
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Current deployment info
CURRENT_SITE="zippy-macaron-c28bbf"
CURRENT_URL="https://zippy-macaron-c28bbf.netlify.app"
TARGET_DOMAIN="jonathon.candlefish.ai"
DOCS_DIR="$HOME/candlefish-ai/projects/jonathon/docs-site"

echo -e "${BLUE}Setting up jonathon.candlefish.ai${NC}"
echo "===================================="
echo

# Check if we have Netlify CLI
if ! command -v netlify &> /dev/null; then
    error "Netlify CLI not found. Please install it first."
fi

# Instructions for manual setup
cat << EOF
${GREEN}Manual Setup Instructions:${NC}

Since the docs are currently deployed to: ${YELLOW}$CURRENT_URL${NC}

We need to either:

${BLUE}Option 1: Configure subdomain on current site${NC}
1. Go to: https://app.netlify.com/sites/$CURRENT_SITE/settings/domain
2. Click "Add custom domain"
3. Enter: $TARGET_DOMAIN
4. Follow DNS instructions

${BLUE}Option 2: Move to Candlefish Grotto project${NC}
1. Download the deployed files from $CURRENT_SITE
2. Go to your Candlefish Grotto site in Netlify
3. Create a new deploy with path-based routing:
   - Path: /jonathon/*
   - Or use branch deploys for subdomain

${BLUE}Option 3: Use Netlify API (Automated)${NC}
Since you have Netlify API access via AWS Secrets, we can automate this.

EOF

# Create API configuration script
cat > "$HOME/candlefish-ai/projects/jonathon/scripts/netlify-api-config.js" << 'SCRIPT'
#!/usr/bin/env node
/**
 * Configure Netlify subdomain via API
 * Requires NETLIFY_AUTH_TOKEN environment variable
 */

const https = require('https');

// Configuration
const NETLIFY_TOKEN = process.env.NETLIFY_AUTH_TOKEN;
const SITE_ID = 'zippy-macaron-c28bbf';
const CUSTOM_DOMAIN = 'jonathon.candlefish.ai';

if (!NETLIFY_TOKEN) {
    console.error('Error: NETLIFY_AUTH_TOKEN environment variable not set');
    console.log('Get your token from: https://app.netlify.com/user/applications#personal-access-tokens');
    process.exit(1);
}

// Add custom domain to site
async function addCustomDomain() {
    const data = JSON.stringify({
        domain: CUSTOM_DOMAIN
    });

    const options = {
        hostname: 'api.netlify.com',
        port: 443,
        path: `/api/v1/sites/${SITE_ID}/domains`,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${NETLIFY_TOKEN}`,
            'Content-Length': data.length
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                if (res.statusCode === 201 || res.statusCode === 200) {
                    console.log('✅ Custom domain added successfully!');
                    resolve(JSON.parse(body));
                } else {
                    console.error(`Error: ${res.statusCode} - ${body}`);
                    reject(new Error(body));
                }
            });
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

// Get site info
async function getSiteInfo() {
    const options = {
        hostname: 'api.netlify.com',
        port: 443,
        path: `/api/v1/sites/${SITE_ID}`,
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${NETLIFY_TOKEN}`
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    resolve(JSON.parse(body));
                } else {
                    reject(new Error(`Error: ${res.statusCode} - ${body}`));
                }
            });
        });

        req.on('error', reject);
        req.end();
    });
}

// Main execution
async function main() {
    try {
        console.log('Fetching site information...');
        const siteInfo = await getSiteInfo();
        console.log(`Site: ${siteInfo.name}`);
        console.log(`Current URL: ${siteInfo.url}`);
        
        console.log(`\nAdding custom domain: ${CUSTOM_DOMAIN}`);
        await addCustomDomain();
        
        console.log('\nNext steps:');
        console.log('1. Configure DNS:');
        console.log(`   - Add CNAME record: jonathon -> ${SITE_ID}.netlify.app`);
        console.log('2. Wait for DNS propagation (5-30 minutes)');
        console.log('3. Netlify will automatically provision SSL');
        
    } catch (error) {
        console.error('Failed:', error.message);
        process.exit(1);
    }
}

main();
SCRIPT

chmod +x "$HOME/candlefish-ai/projects/jonathon/scripts/netlify-api-config.js"

# Create DNS configuration guide
cat > "$HOME/candlefish-ai/projects/jonathon/DNS_SETUP.md" << EOF
# DNS Configuration for jonathon.candlefish.ai

## Current Status
- **Deployed to**: $CURRENT_URL
- **Target domain**: $TARGET_DOMAIN

## DNS Setup Required

Add this record to your DNS provider for candlefish.ai:

\`\`\`
Type: CNAME
Name: jonathon
Value: $CURRENT_SITE.netlify.app
TTL: 300
\`\`\`

## If Using Cloudflare
1. Log in to Cloudflare
2. Select candlefish.ai domain
3. Go to DNS settings
4. Add CNAME record as above
5. Set Proxy status to "DNS only" (gray cloud)

## If Using Route53
1. Go to Route53 console
2. Select your hosted zone for candlefish.ai
3. Create Record
4. Record type: CNAME
5. Record name: jonathon
6. Value: $CURRENT_SITE.netlify.app

## Verification
After DNS propagates (5-30 minutes), test:
\`\`\`bash
curl -I https://jonathon.candlefish.ai
\`\`\`

## Alternative: Branch Deploy
If you want to keep docs in the main Candlefish Grotto project:
1. Create a \`jonathon\` branch in your Grotto repo
2. Configure branch deploys in Netlify
3. This will create jonathon--candlefish.netlify.app
EOF

echo
echo -e "${GREEN}Setup scripts created!${NC}"
echo
echo "To configure the subdomain:"
echo "1. Set your Netlify token:"
echo "   export NETLIFY_AUTH_TOKEN='your-token-here'"
echo "2. Run the API configuration:"
echo "   node $HOME/candlefish-ai/projects/jonathon/scripts/netlify-api-config.js"
echo
echo "Or follow the manual instructions above."
echo
echo "DNS configuration guide saved to: DNS_SETUP.md"