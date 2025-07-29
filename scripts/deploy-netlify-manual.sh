#!/bin/bash
# Manual Netlify deployment using drag-and-drop approach

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Manual Netlify Deployment Instructions${NC}"
echo "======================================="
echo
echo "Since automated deployment requires interactive input, please follow these steps:"
echo
echo -e "${GREEN}Option 1: Drag and Drop (Easiest)${NC}"
echo "1. Open https://app.netlify.com/drop"
echo "2. Open Finder to: ~/candlefish-ai/projects/jonathon/docs-site"
echo "3. Drag the entire 'docs-site' folder to the Netlify drop zone"
echo "4. Your site will be instantly deployed!"
echo
echo -e "${GREEN}Option 2: GitHub Deployment${NC}"
echo "1. First push to GitHub:"
echo "   cd ~/candlefish-ai/projects/jonathon"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit'"
echo "   git remote add origin https://github.com/candlefish-ai/claude-setup.git"
echo "   git push -u origin main"
echo
echo "2. Then in Netlify:"
echo "   - Go to https://app.netlify.com"
echo "   - Click 'Add new site' > 'Import an existing project'"
echo "   - Connect to GitHub and select the repository"
echo "   - Set publish directory to: docs-site"
echo "   - Deploy!"
echo
echo -e "${GREEN}Option 3: Netlify CLI (Manual Steps)${NC}"
echo "1. cd ~/candlefish-ai/projects/jonathon/docs-site"
echo "2. netlify init"
echo "3. Choose 'Create & configure a new site'"
echo "4. Team: candlefish | bart"
echo "5. Site name: candlefish-claude-docs"
echo "6. netlify deploy --prod --dir ."
echo
echo -e "${YELLOW}After Deployment:${NC}"
echo "1. Go to Site settings > Domain management"
echo "2. Add custom domain: docs.candlefish.ai"
echo "3. Configure DNS with CNAME: docs -> candlefish-claude-docs.netlify.app"
echo
echo -e "${BLUE}Files Ready for Deployment:${NC}"
ls -la ~/candlefish-ai/projects/jonathon/docs-site/