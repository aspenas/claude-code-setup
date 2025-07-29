# Setting Up jonathon.candlefish.ai

## Current Situation
- **Documentation deployed to**: https://zippy-macaron-c28bbf.netlify.app ✅
- **Want to access at**: https://jonathon.candlefish.ai
- **Main site**: Managed by Candlefish Grotto Netlify project

## Simplest Solution (5 minutes)

### Step 1: Add Custom Domain in Netlify
1. Go to: https://app.netlify.com/sites/zippy-macaron-c28bbf/settings/domain
2. Click **"Add custom domain"**
3. Enter: `jonathon.candlefish.ai`
4. Click **"Verify"**
5. Netlify will provide DNS instructions

### Step 2: Configure DNS
Add this record to your DNS provider (Cloudflare/Route53/etc):

```
Type: CNAME
Name: jonathon
Value: zippy-macaron-c28bbf.netlify.app
TTL: 300 (or Auto)
```

**For Cloudflare:**
- Set Proxy status to "DNS only" (gray cloud icon)

### Step 3: Wait & Verify
- DNS propagation: 5-30 minutes
- Netlify will auto-provision SSL certificate
- Test: https://jonathon.candlefish.ai

## Alternative: Subdirectory on Main Site

If you prefer to have it under the main Candlefish site structure:

1. In your Candlefish Grotto Netlify project
2. Deploy the docs to a subdirectory: `/jonathon/`
3. Access at: https://candlefish.ai/jonathon/

## Using AWS Secrets (If Available)

If you have Netlify API token in AWS Secrets:
```bash
cd ~/candlefish-ai/projects/jonathon
./scripts/configure-subdomain-aws.sh
```

## Quick Test

Once DNS is configured:
```bash
# Test if subdomain is resolving
dig jonathon.candlefish.ai

# Test HTTPS access
curl -I https://jonathon.candlefish.ai
```

## Result

Your documentation will be accessible at:
- **Primary**: https://jonathon.candlefish.ai
- **Netlify URL**: https://zippy-macaron-c28bbf.netlify.app (always works)

---

The easiest approach is Option 1 - just add the custom domain in Netlify dashboard and configure DNS. This keeps the deployment separate and clean.