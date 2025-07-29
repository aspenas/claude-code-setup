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
