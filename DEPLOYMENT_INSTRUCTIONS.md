# Deployment Instructions for docs.candlefish.ai

## Overview

The documentation has been prepared with Candlefish AI branding and is ready for deployment to docs.candlefish.ai via Netlify.

## Files Created

### Documentation Site (`docs-site/`)
- **index.html** - Main landing page with Candlefish AI branding
- **complete-setup-guide.html** - Converted from markdown
- **security-guide.html** - Security best practices
- **quick-reference.html** - Commands cheat sheet
- **aws-setup.html** - AWS configuration guide
- **project-templates.html** - Starter templates
- **troubleshooting.html** - Common issues
- **netlify.toml** - Netlify configuration
- **logo/** - Candlefish AI logo assets

### Deployment Scripts
1. **deploy-docs.sh** - Main deployment script
2. **convert-docs-to-html.js** - Converts markdown to branded HTML
3. **setup-github-repo.sh** - Prepares GitHub repository

## Deployment Steps

### 1. Deploy to Netlify

```bash
cd ~/candlefish-ai/projects/jonathon
./scripts/deploy-docs.sh
```

This will:
- Check/install Netlify CLI
- Deploy the docs-site directory
- Configure custom domain

### 2. Configure DNS

Add a CNAME record to your DNS:
```
Type: CNAME
Name: docs
Value: candlefish-claude-docs.netlify.app
```

Or use Netlify DNS for automatic configuration.

### 3. Create GitHub Repository (Optional)

```bash
./scripts/setup-github-repo.sh
```

Then follow the instructions to push to GitHub.

## Design Features

The documentation site matches Candlefish AI branding:
- **Color Scheme**: Black background with teal accents (#00CED1)
- **Typography**: Berkeley Mono for code, Inter for text
- **Layout**: Clean, minimal design with smooth animations
- **Mobile Responsive**: Works on all devices
- **Dark Theme**: Consistent with main site

## Key URLs

- **Staging**: https://candlefish-claude-docs.netlify.app
- **Production**: https://docs.candlefish.ai (after DNS configuration)
- **GitHub**: https://github.com/candlefish-ai/claude-setup (if created)

## Testing

After deployment, verify:
1. All pages load correctly
2. Navigation works
3. Code blocks are formatted properly
4. Logo displays correctly
5. Mobile responsiveness

## Maintenance

To update documentation:
1. Edit markdown files in `docs/`
2. Run `node scripts/convert-docs-to-html.js`
3. Deploy with `./scripts/deploy-docs.sh`

## Support

Contact: patrick@candlefish.ai