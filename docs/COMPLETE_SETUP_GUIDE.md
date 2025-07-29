# Jonathon's Complete Claude Code Setup Guide

*By Patrick Smith (patrick@candlefish.ai) - Candlefish AI*

## Overview

This guide provides a comprehensive walkthrough for setting up a complete Claude Code development environment from scratch. It covers everything from initial Mac setup to advanced Claude Code configurations.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Mac Setup](#initial-mac-setup)
3. [Core Tools Installation](#core-tools-installation)
4. [Claude Code Installation](#claude-code-installation)
5. [AWS Account Setup](#aws-account-setup)
6. [Development Environment](#development-environment)
7. [Project Templates](#project-templates)
8. [Security & Credentials](#security--credentials)
9. [Advanced Configuration](#advanced-configuration)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements
- macOS 12.0 or later
- 8GB RAM minimum (16GB recommended)
- 20GB free disk space
- Admin access to your Mac

### Accounts Needed
- [ ] Anthropic Console account
- [ ] AWS account (new one will be created)
- [ ] GitHub account
- [ ] OpenAI account (optional)

## Initial Mac Setup

### 1. Install Xcode Command Line Tools
```bash
xcode-select --install
```

### 2. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Configure Shell
Add Homebrew to your PATH:
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

## Core Tools Installation

### Essential Command Line Tools
```bash
# Package managers and build tools
brew install git curl wget jq

# Modern CLI tools
brew install ripgrep fd bat eza gh httpie tree tmux direnv

# Development tools
brew install node nvm python@3.12 go rust
```

### Node.js Setup
```bash
# Install nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Add to shell
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
source ~/.zshrc

# Install Node.js
nvm install 20
nvm use 20
nvm alias default 20

# Install global packages
npm install -g pnpm typescript tsx nodemon pm2
```

## Claude Code Installation

### 1. Install Claude Code Package
```bash
# Install latest Claude Code
npm install -g @anthropic-ai/claude-code@latest

# Verify installation
claude-code --version
```

### 2. Create Directory Structure
```bash
# Create Claude directories
mkdir -p ~/.claude/{bin,config,projects,sessions,metrics,commands,templates}

# Create project directories
mkdir -p ~/projects/{personal,work,experiments}
```

### 3. Configure Claude Code

Create `~/.claude/config.yml`:
```yaml
# Claude Code Configuration
defaultModel: claude-opus-4-20250514
defaultContext: 100000
maximumContext: 200000

# Access permissions
webAccessUnrestricted: true
fileSystemAccessUnrestricted: true
allowUnmentionedDomains: true
allowUnmentionedPaths: true

# Tool permissions
allowedTools:
  - "Bash(git *)"
  - "Bash(python3 *)"
  - "Bash(pip *)"
  - "Bash(npm *)"
  - "Bash(pnpm *)"
  - "Bash(curl *)"
  - "Bash(wget *)"
  - "Bash(httpie *)"
  - "Bash(aws *)"
  - "Bash(docker *)"

# Project settings
projectRoot: "$HOME/projects"
autoTrust: true

# Performance
enableCaching: true
parallelToolCalls: true

# Logging
logLevel: info
metricsEnabled: true
```

### 4. Create Wrapper Scripts

Create `~/.claude/bin/claude`:
```bash
#!/bin/bash
# Claude Code wrapper with enhanced features

# Default to Opus 4 model
export CLAUDE_DEFAULT_MODEL="claude-opus-4-20250514"

# Load API keys if available
if [ -f "$HOME/.claude/api-keys.env" ]; then
    source "$HOME/.claude/api-keys.env"
fi

# Execute Claude Code with enhanced options
exec claude-code "$@"
```

Create `~/.claude/bin/claude-max`:
```bash
#!/bin/bash
# Claude with maximum context window
exec claude-code --context 200k "$@"
```

Create `~/.claude/bin/claude-think`:
```bash
#!/bin/bash
# Claude with step-by-step thinking
exec claude-code --thinking "$@"
```

Make scripts executable:
```bash
chmod +x ~/.claude/bin/*
```

### 5. Configure Shell Aliases

Add to `~/.zshrc`:
```bash
# Claude Code Configuration
export CLAUDE_HOME="$HOME/.claude"
export PATH="$CLAUDE_HOME/bin:$PATH"

# Aliases
alias c='claude'
alias cmax='claude-max'
alias cthink='claude-think'
alias cc='claude-code'

# Functions
claude-project() {
    local project_name="$1"
    if [ -z "$project_name" ]; then
        echo "Usage: claude-project <project-name>"
        return 1
    fi
    
    cd "$HOME/projects/$project_name" && claude
}

# Quick project navigation
alias projects='cd ~/projects'
alias projects='cd ~/projects'
```

## AWS Account Setup

### 1. Create AWS Account
1. Go to https://aws.amazon.com
2. Click "Create an AWS Account"
3. Follow the signup process
4. Enable MFA on root account

### 2. Create IAM User
```bash
# After installing AWS CLI
brew install awscli

# Configure with root credentials temporarily
aws configure

# Create admin user
aws iam create-user --user-name jonathon-admin
aws iam attach-user-policy --user-name jonathon-admin \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access key
aws iam create-access-key --user-name jonathon-admin
```

### 3. Configure AWS CLI
```bash
# Configure with new IAM user
aws configure
# Enter the Access Key ID and Secret Access Key from the previous step
# Default region: us-east-1
# Default output: json
```

### 4. Set Up AWS Resources

Create S3 bucket for projects:
```bash
aws s3 mb s3://jonathon-projects-$(date +%s)
```

Create Secrets Manager for API keys:
```bash
# Create a secret for API keys
aws secretsmanager create-secret \
    --name "jonathon/api-keys" \
    --description "API keys for Jonathon's projects" \
    --secret-string '{
        "ANTHROPIC_API_KEY": "your-key-here",
        "OPENAI_API_KEY": "your-key-here",
        "GITHUB_TOKEN": "your-token-here"
    }'
```

### 5. Install AWS Tools
```bash
# AWS session manager
brew install aws-vault

# AWS SAM for serverless
brew install aws-sam-cli

# AWS CDK
npm install -g aws-cdk
```

## Development Environment

### 1. VS Code Installation
```bash
# Install VS Code
brew install --cask visual-studio-code

# Install extensions
code --install-extension ms-python.python
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension ms-vscode.typescript-language-features
code --install-extension bradlc.vscode-tailwindcss
code --install-extension prisma.prisma
code --install-extension GraphQL.vscode-graphql
code --install-extension amazonwebservices.aws-toolkit-vscode
```

### 2. Database Setup
```bash
# PostgreSQL
brew install postgresql@16
brew services start postgresql@16

# Redis
brew install redis
brew services start redis

# Database GUI
brew install --cask tableplus
```

### 3. Container Tools
```bash
# Docker Desktop
brew install --cask docker

# Container tools
brew install docker-compose lazydocker
```

### 4. API Testing Tools
```bash
# Postman
brew install --cask postman

# Command line tools
brew install httpie curl jq
```

## Project Templates

### 1. Next.js + TypeScript Template

Create `~/.claude/templates/create-nextjs-project.sh`:
```bash
#!/bin/bash
# Create a new Next.js project with Candlefish AI standards

project_name="$1"
if [ -z "$project_name" ]; then
    read -p "Enter project name: " project_name
fi

# Create project
pnpm create next-app@latest "$project_name" \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --no-src-dir \
    --import-alias "@/*"

cd "$project_name"

# Install additional dependencies
pnpm add @anthropic-ai/sdk openai zod prisma @prisma/client
pnpm add -D @types/node prettier eslint-config-prettier

# Create project structure
mkdir -p {services,lib,components,hooks,utils,types}

# Initialize Prisma
pnpm prisma init

# Create basic service structure
cat > services/ai/claude.service.ts << 'EOF'
import Anthropic from '@anthropic-ai/sdk';

export class ClaudeService {
  private client: Anthropic;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
  }

  async generateCompletion(prompt: string) {
    const response = await this.client.messages.create({
      model: 'claude-opus-4-20250514',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 4096,
    });
    
    return response.content[0].text;
  }
}
EOF

# Create environment file
cat > .env.local << EOE
# API Keys
ANTHROPIC_API_KEY=
OPENAI_API_KEY=

# Database
DATABASE_URL="postgresql://localhost:5432/$project_name"

# NextAuth
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=$(openssl rand -base64 32)
EOE

# Initialize git
git init
git add .
git commit -m "Initial commit: $project_name"

echo "Project $project_name created successfully!"
echo "Next steps:"
echo "  cd $project_name"
echo "  pnpm dev"
```

Make executable:
```bash
chmod +x ~/.claude/templates/*.sh
```

### 2. Python FastAPI Template

Create `~/.claude/templates/create-python-project.sh`:
```bash
#!/bin/bash
# Create a new Python project with Candlefish AI standards

project_name="$1"
if [ -z "$project_name" ]; then
    read -p "Enter project name: " project_name
fi

mkdir "$project_name"
cd "$project_name"

# Initialize poetry
poetry init -n \
    --name "$project_name" \
    --dependency fastapi \
    --dependency uvicorn \
    --dependency anthropic \
    --dependency openai \
    --dependency pydantic \
    --dependency python-dotenv \
    --dev-dependency pytest \
    --dev-dependency black \
    --dev-dependency ruff

# Install dependencies
poetry install

# Create project structure
mkdir -p {app,services,models,utils,tests}

# Create main app
cat > app/main.py << 'EOF'
from fastapi import FastAPI
from pydantic import BaseModel
import anthropic

app = FastAPI(title="Jonathon's API")

class GenerateRequest(BaseModel):
    prompt: str
    model: str = "claude-opus-4-20250514"

@app.post("/generate")
async def generate(request: GenerateRequest):
    # Implementation here
    return {"message": "Generated"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
EOF

# Create .env file
cat > .env << EOF
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
EOF

# Initialize git
git init
echo ".env" > .gitignore
echo "__pycache__/" >> .gitignore
echo ".pytest_cache/" >> .gitignore
git add .
git commit -m "Initial commit: $project_name"

echo "Project $project_name created successfully!"
```

## Security & Credentials

### 1. API Key Management

Create `~/.claude/scripts/setup-api-keys.sh`:
```bash
#!/bin/bash
# Secure API key setup

echo "Setting up API keys securely..."

# Create secure directory
mkdir -p ~/.claude/secrets
chmod 700 ~/.claude/secrets

# Get API keys
read -s -p "Enter Anthropic API Key: " anthropic_key
echo
read -s -p "Enter OpenAI API Key (optional): " openai_key
echo
read -s -p "Enter GitHub Token: " github_token
echo

# Store in AWS Secrets Manager
aws secretsmanager create-secret \
    --name "claude-code/api-keys" \
    --secret-string "{
        \"ANTHROPIC_API_KEY\": \"$anthropic_key\",
        \"OPENAI_API_KEY\": \"$openai_key\",
        \"GITHUB_TOKEN\": \"$github_token\"
    }" || \
aws secretsmanager update-secret \
    --secret-id "claude-code/api-keys" \
    --secret-string "{
        \"ANTHROPIC_API_KEY\": \"$anthropic_key\",
        \"OPENAI_API_KEY\": \"$openai_key\",
        \"GITHUB_TOKEN\": \"$github_token\"
    }"

# Create local env file (encrypted)
cat > ~/.claude/secrets/api-keys.env << EOF
export ANTHROPIC_API_KEY="$anthropic_key"
export OPENAI_API_KEY="$openai_key"
export GITHUB_TOKEN="$github_token"
EOF

chmod 600 ~/.claude/secrets/api-keys.env

echo "API keys stored securely!"
```

### 2. SSH Key Setup
```bash
# Generate SSH key for GitHub
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/jonathon_github

# Add to SSH agent
ssh-add ~/.ssh/jonathon_github

# Display public key to add to GitHub
cat ~/.ssh/jonathon_github.pub
```

### 3. Git Configuration
```bash
# Configure git
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
```

## Advanced Configuration

### 1. Claude Code Custom Commands

Create `~/.claude/commands/analyze.yml`:
```yaml
name: analyze
description: Analyze codebase and provide insights
prompt: |
  Analyze the current codebase and provide:
  1. Architecture overview
  2. Code quality assessment
  3. Security considerations
  4. Performance optimizations
  5. Suggested improvements
```

### 2. Project-Specific Configuration

Create `~/.claude/projects/jonathon/.claude.yml`:
```yaml
# Project-specific Claude configuration
defaultModel: claude-opus-4-20250514
context: 200000

# Custom instructions
instructions: |
  - Follow Candlefish AI coding standards
  - Use TypeScript strict mode
  - Implement comprehensive error handling
  - Add JSDoc comments for public APIs
  - Write tests for all new features

# Auto-imports
imports:
  - "@/services"
  - "@/lib"
  - "@/types"
```

### 3. Performance Optimization

Create `~/.claude/config/performance.yml`:
```yaml
# Performance settings
cache:
  enabled: true
  ttl: 3600
  maxSize: 1GB

parallel:
  maxConcurrent: 10
  timeout: 30000

memory:
  maxHeap: 4GB
  gcInterval: 300
```

## Troubleshooting

### Common Issues

#### 1. Claude Code not found
```bash
# Check installation
npm list -g @anthropic-ai/claude-code

# Reinstall if needed
npm uninstall -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code@latest
```

#### 2. Permission errors
```bash
# Fix permissions
sudo chown -R $(whoami) ~/.claude
chmod -R 755 ~/.claude
```

#### 3. API key issues
```bash
# Test API key
curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

### Debug Mode
```bash
# Run Claude Code in debug mode
CLAUDE_DEBUG=true claude-code

# Check logs
tail -f ~/.claude/logs/claude.log
```

### Reset Configuration
```bash
# Backup current config
cp -r ~/.claude ~/.claude.backup

# Reset to defaults
rm -rf ~/.claude
claude-code --init
```

## Quick Reference

### Essential Commands
```bash
# Start Claude Code
c                     # Quick start
claude                # Standard start
claude-max            # Max context (200k)
claude-think          # Thinking mode

# Project commands
claude-project myapp  # Open project
claude --cwd ./path   # Specific directory

# Configuration
claude --config       # Show config
claude --version      # Show version
```

### Keyboard Shortcuts
- `Ctrl+C` - Cancel current operation
- `Ctrl+D` - Exit Claude Code
- `Ctrl+L` - Clear screen
- `Ctrl+R` - Search command history

### Model Selection
```bash
# Use specific model
claude --model claude-opus-4-20250514
claude --model claude-3-5-sonnet-20241022
claude --model claude-3-haiku-20240307
```

### Context Window
```bash
# Set context size
claude --context 50k    # 50,000 tokens
claude --context 100k   # 100,000 tokens
claude --context 200k   # 200,000 tokens (max)
```

## Next Steps

1. **Get API Keys**
   - Anthropic: https://console.anthropic.com/api-keys
   - OpenAI: https://platform.openai.com/api-keys
   - GitHub: https://github.com/settings/tokens

2. **Join Communities**
   - Claude Discord: https://discord.gg/anthropic
   - Candlefish AI Support: patrick@candlefish.ai

3. **Explore Resources**
   - Claude Cookbook: https://github.com/anthropics/anthropic-cookbook
   - API Documentation: https://docs.anthropic.com
   - Community Projects: https://github.com/topics/claude-ai

4. **Start Building**
   - Create your first project: `~/.claude/templates/create-nextjs-project.sh myapp`
   - Explore Claude's capabilities: `claude`
   - Build something amazing!

---

## Support

For issues or questions:
- GitHub Issues: https://github.com/candlefish-ai/claude-setup
- Email: patrick@candlefish.ai
- Documentation: https://docs.candlefish.ai