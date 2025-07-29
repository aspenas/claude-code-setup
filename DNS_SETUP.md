# DNS Configuration for jonathon.candlefish.ai

## Current Status
- **Deployed to**: https://zippy-macaron-c28bbf.netlify.app
- **Target domain**: jonathon.candlefish.ai

## DNS Setup Required

Add this record to your DNS provider for candlefish.ai:

```
Type: CNAME
Name: jonathon
Value: zippy-macaron-c28bbf.netlify.app
TTL: 300
```

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
6. Value: zippy-macaron-c28bbf.netlify.app

## Verification
After DNS propagates (5-30 minutes), test:
```bash
curl -I https://jonathon.candlefish.ai
```

## Alternative: Branch Deploy
If you want to keep docs in the main Candlefish Grotto project:
1. Create a `jonathon` branch in your Grotto repo
2. Configure branch deploys in Netlify
3. This will create jonathon--candlefish.netlify.app
