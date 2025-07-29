#!/bin/bash
# Setup GitHub Repository for Claude Documentation
# Author: Patrick Smith (patrick@candlefish.ai)

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Create README for GitHub
create_github_readme() {
    cat > README.md << 'EOF'
# Claude Code Setup Documentation

Complete setup guide for building AI-powered applications with Claude Code, AWS integration, and enterprise-grade security.

## 🚀 Quick Start

```bash
# Clone this repository
git clone https://github.com/candlefish-ai/claude-setup.git
cd claude-setup

# Run the setup script
./scripts/master-setup.sh

# Start Claude Code
claude
```

## 📚 Documentation

Full documentation is available at: https://docs.candlefish.ai

### Guides Included:
- **Complete Setup Guide** - Step-by-step environment setup
- **Security & Credentials** - Best practices for API key management
- **Quick Reference** - Essential commands and shortcuts
- **AWS Setup** - Cloud infrastructure configuration
- **Project Templates** - Production-ready starter templates
- **Troubleshooting** - Common issues and solutions

## 🛠️ What's Included

- **Automated Setup Scripts** - One-click installation
- **Claude Code Configuration** - Optimized for Opus 4 model
- **AWS Infrastructure** - S3, Secrets Manager, DynamoDB
- **Project Templates** - Next.js + TypeScript + AI
- **Security Tools** - API key management, encryption

## 💡 Features

- ✅ 2M input / 400k output token limits with Opus 4
- ✅ Multi-provider AI support (Anthropic + OpenAI)
- ✅ Enterprise-grade security implementation
- ✅ Production-ready project templates
- ✅ Comprehensive documentation

## 📞 Support

- Documentation: https://docs.candlefish.ai
- Email: patrick@candlefish.ai
- Company: https://candlefish.ai

## 📄 License

MIT License - see LICENSE file for details.

---

Created by [Patrick Smith](mailto:patrick@candlefish.ai) - [Candlefish AI](https://candlefish.ai)
EOF
}

# Create .gitignore
create_gitignore() {
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
*.log

# Environment
.env
.env.local
.env.*.local

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Build outputs
dist/
build/
.next/
out/

# Credentials
*.pem
*.key
*-credentials.json
secrets/

# Temporary
tmp/
temp/
*.tmp
*.bak

# Python
__pycache__/
*.py[cod]
venv/
.venv/

# Netlify
.netlify/
EOF
}

# Initialize git repository
init_git_repo() {
    log "Initializing Git repository..."
    
    cd "$HOME/candlefish-ai/projects/jonathon"
    
    # Initialize git if not already
    if [ ! -d ".git" ]; then
        git init
        info "Git repository initialized"
    fi
    
    # Create README and .gitignore
    create_github_readme
    create_gitignore
    
    # Add all files
    git add .
    git commit -m "Initial commit: Claude Code setup documentation and tools

- Complete setup scripts for macOS environment
- Documentation for Claude Code, AWS, and security
- Project templates for Next.js + AI
- Deployment tools for Netlify
- Comprehensive guides and quick reference"
    
    info "Repository ready for GitHub"
}

# Instructions for GitHub
show_github_instructions() {
    echo
    echo -e "${BLUE}GitHub Repository Setup Instructions${NC}"
    echo "======================================"
    echo
    echo "1. Create a new repository on GitHub:"
    echo "   - Go to: https://github.com/new"
    echo "   - Name: claude-setup"
    echo "   - Description: Complete Claude Code development environment setup"
    echo "   - Make it public"
    echo "   - Don't initialize with README (we have one)"
    echo
    echo "2. Add GitHub remote and push:"
    echo "   cd $HOME/candlefish-ai/projects/jonathon"
    echo "   git remote add origin https://github.com/candlefish-ai/claude-setup.git"
    echo "   git branch -M main"
    echo "   git push -u origin main"
    echo
    echo "3. Enable GitHub Pages (optional):"
    echo "   - Go to Settings > Pages"
    echo "   - Source: Deploy from a branch"
    echo "   - Branch: main, folder: /docs-site"
    echo
}

# Main execution
main() {
    echo -e "${BLUE}Setting up GitHub repository...${NC}"
    echo
    
    init_git_repo
    show_github_instructions
    
    echo -e "${GREEN}✅ Git repository prepared!${NC}"
}

main "$@"