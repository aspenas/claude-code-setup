# Security and Credentials Management Guide

*By Patrick Smith (patrick@candlefish.ai) - Candlefish AI*

## Overview

This guide covers comprehensive security practices and credential management for Jonathon's development environment. Follow these practices to maintain a secure development workflow.

## Table of Contents

1. [API Key Management](#api-key-management)
2. [AWS Credentials](#aws-credentials)
3. [Environment Variables](#environment-variables)
4. [SSH Keys](#ssh-keys)
5. [Password Management](#password-management)
6. [Secret Storage Options](#secret-storage-options)
7. [Security Best Practices](#security-best-practices)
8. [Emergency Procedures](#emergency-procedures)

## API Key Management

### 1. Obtaining API Keys

#### Anthropic (Claude)
1. Visit https://console.anthropic.com
2. Navigate to API Keys section
3. Click "Create Key"
4. Name your key (e.g., "Jonathon Development")
5. Copy the key immediately (shown only once)
6. Store securely using methods below

#### OpenAI
1. Visit https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Name your key descriptively
4. Copy immediately
5. Set usage limits to prevent overages

#### GitHub Personal Access Token
1. Visit https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (full control)
   - `workflow` (GitHub Actions)
   - `read:org` (organization access)
4. Set expiration (recommend 90 days)
5. Generate and copy token

### 2. Secure Storage Methods

#### Method 1: AWS Secrets Manager (Recommended)
```bash
# Store API key in AWS Secrets Manager
aws secretsmanager create-secret \
    --name "jonathon/anthropic-api-key" \
    --secret-string "sk-ant-your-key-here"

# Retrieve API key
aws secretsmanager get-secret-value \
    --secret-id "jonathon/anthropic-api-key" \
    --query SecretString --output text
```

#### Method 2: macOS Keychain
```bash
# Store in Keychain
security add-generic-password \
    -a "$USER" \
    -s "ANTHROPIC_API_KEY" \
    -w "sk-ant-your-key-here"

# Retrieve from Keychain
security find-generic-password \
    -a "$USER" \
    -s "ANTHROPIC_API_KEY" \
    -w
```

#### Method 3: Encrypted File Storage
```bash
# Create encrypted storage
mkdir -p ~/.jonathon/secrets
chmod 700 ~/.jonathon/secrets

# Encrypt API keys
echo "ANTHROPIC_API_KEY=sk-ant-..." > ~/.jonathon/secrets/api-keys.env
openssl enc -aes-256-cbc -salt -pbkdf2 \
    -in ~/.jonathon/secrets/api-keys.env \
    -out ~/.jonathon/secrets/api-keys.env.enc
rm ~/.jonathon/secrets/api-keys.env

# Decrypt when needed
openssl enc -aes-256-cbc -d -pbkdf2 \
    -in ~/.jonathon/secrets/api-keys.env.enc \
    -out ~/.jonathon/secrets/api-keys.env
```

### 3. Loading API Keys Securely

Create `~/.jonathon/scripts/load-secrets.sh`:
```bash
#!/bin/bash
# Secure secret loading script

# Function to load from AWS Secrets Manager
load_from_aws() {
    echo "Loading secrets from AWS Secrets Manager..."
    
    export ANTHROPIC_API_KEY=$(aws secretsmanager get-secret-value \
        --secret-id "jonathon/anthropic-api-key" \
        --query SecretString --output text 2>/dev/null)
    
    export OPENAI_API_KEY=$(aws secretsmanager get-secret-value \
        --secret-id "jonathon/openai-api-key" \
        --query SecretString --output text 2>/dev/null)
    
    export GITHUB_TOKEN=$(aws secretsmanager get-secret-value \
        --secret-id "jonathon/github-token" \
        --query SecretString --output text 2>/dev/null)
}

# Function to load from Keychain
load_from_keychain() {
    echo "Loading secrets from macOS Keychain..."
    
    export ANTHROPIC_API_KEY=$(security find-generic-password \
        -a "$USER" -s "ANTHROPIC_API_KEY" -w 2>/dev/null)
    
    export OPENAI_API_KEY=$(security find-generic-password \
        -a "$USER" -s "OPENAI_API_KEY" -w 2>/dev/null)
    
    export GITHUB_TOKEN=$(security find-generic-password \
        -a "$USER" -s "GITHUB_TOKEN" -w 2>/dev/null)
}

# Function to load from encrypted file
load_from_file() {
    local secrets_file="$HOME/.jonathon/secrets/api-keys.env"
    
    if [ -f "${secrets_file}.enc" ]; then
        echo "Enter encryption password:"
        openssl enc -aes-256-cbc -d -pbkdf2 \
            -in "${secrets_file}.enc" \
            -out "${secrets_file}"
        
        source "${secrets_file}"
        rm "${secrets_file}"  # Remove decrypted file immediately
    fi
}

# Try loading in order of preference
if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
    load_from_aws
elif command -v security &> /dev/null; then
    load_from_keychain
else
    load_from_file
fi

# Verify loaded
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Warning: ANTHROPIC_API_KEY not loaded"
else
    echo "✓ ANTHROPIC_API_KEY loaded"
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Warning: OPENAI_API_KEY not loaded"
else
    echo "✓ OPENAI_API_KEY loaded"
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Warning: GITHUB_TOKEN not loaded"
else
    echo "✓ GITHUB_TOKEN loaded"
fi
```

## AWS Credentials

### 1. Initial Setup

```bash
# Never use root account for daily work!
# Create IAM user instead

# Configure AWS CLI with IAM user
aws configure
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region: us-east-1
# Default output: json
```

### 2. AWS Vault for Secure Storage

```bash
# Install AWS Vault
brew install aws-vault

# Add credentials to vault
aws-vault add jonathon

# Use credentials
aws-vault exec jonathon -- aws s3 ls

# Set as default for session
aws-vault exec jonathon -- $SHELL
```

### 3. Credential Rotation

```bash
# Rotate access keys monthly
aws iam create-access-key --user-name jonathon-dev

# Update stored credentials
aws-vault remove jonathon
aws-vault add jonathon

# Delete old access key
aws iam delete-access-key --user-name jonathon-dev \
    --access-key-id OLDACCESSKEYID
```

## Environment Variables

### 1. Development Setup

Create `.env.local` (never commit this file):
```bash
# API Keys
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GITHUB_TOKEN=ghp_...

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/jonathon

# AWS (if not using IAM roles)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1

# Application Secrets
NEXTAUTH_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
```

### 2. Using direnv for Automatic Loading

```bash
# Install direnv
brew install direnv

# Add to shell
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc

# Create .envrc in project
cat > .envrc << 'EOF'
# Load secrets securely
source ~/.jonathon/scripts/load-secrets.sh

# Project-specific overrides
export NODE_ENV=development
export LOG_LEVEL=debug
EOF

# Allow direnv for this directory
direnv allow
```

### 3. Production Environment Variables

Never hardcode production secrets. Use:
- AWS Secrets Manager
- Vercel Environment Variables
- Heroku Config Vars
- Docker Secrets

## SSH Keys

### 1. Generate SSH Keys

```bash
# Ed25519 (recommended)
ssh-keygen -t ed25519 -C "jonathon@example.com" \
    -f ~/.ssh/jonathon_github

# RSA (fallback)
ssh-keygen -t rsa -b 4096 -C "jonathon@example.com" \
    -f ~/.ssh/jonathon_github_rsa
```

### 2. SSH Config

Create `~/.ssh/config`:
```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/jonathon_github
    AddKeysToAgent yes
    UseKeychain yes

Host jonathon-server
    HostName your-server.com
    User ubuntu
    IdentityFile ~/.ssh/jonathon_server
    Port 22
    ForwardAgent yes
```

### 3. SSH Agent

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add keys to agent
ssh-add --apple-use-keychain ~/.ssh/jonathon_github

# List loaded keys
ssh-add -l
```

## Password Management

### 1. Generate Strong Passwords

```bash
# Generate random password
openssl rand -base64 32

# Generate memorable passphrase
brew install pwgen
pwgen -s 32 1

# Generate with specific requirements
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
```

### 2. Password Storage

#### Option 1: 1Password CLI
```bash
# Install 1Password CLI
brew install --cask 1password-cli

# Sign in
op signin

# Create item
op item create --category=login \
    --title="Jonathon Dev" \
    --vault="Development" \
    username=admin \
    password="$(openssl rand -base64 32)"

# Retrieve password
op item get "Jonathon Dev" --field password
```

#### Option 2: macOS Keychain
```bash
# Store password
security add-generic-password \
    -a "jonathon" \
    -s "PostgreSQL Dev" \
    -w

# Retrieve password
security find-generic-password \
    -a "jonathon" \
    -s "PostgreSQL Dev" \
    -w
```

## Secret Storage Options

### 1. Development Secrets

```bash
# Local development hierarchy
~/.jonathon/
├── secrets/
│   ├── api-keys.env.enc    # Encrypted API keys
│   ├── aws-creds.enc       # Encrypted AWS credentials
│   └── ssh-keys/           # SSH private keys
├── config/
│   └── development.yml     # Non-sensitive config
└── scripts/
    └── load-secrets.sh     # Secret loading script
```

### 2. Cloud Secret Storage

#### AWS Secrets Manager
```bash
# Store complex secret
aws secretsmanager create-secret \
    --name "jonathon/app-config" \
    --secret-string '{
        "database": {
            "host": "localhost",
            "port": 5432,
            "name": "jonathon",
            "user": "admin",
            "password": "secure-password"
        },
        "redis": {
            "url": "redis://localhost:6379"
        }
    }'

# Retrieve in application
const AWS = require('aws-sdk');
const client = new AWS.SecretsManager();

async function getSecret() {
    const data = await client.getSecretValue({
        SecretId: 'jonathon/app-config'
    }).promise();
    
    return JSON.parse(data.SecretString);
}
```

#### HashiCorp Vault
```bash
# Install Vault
brew install vault

# Start dev server
vault server -dev

# Store secret
vault kv put secret/jonathon \
    anthropic_key="sk-ant-..." \
    openai_key="sk-..."

# Retrieve secret
vault kv get -format=json secret/jonathon
```

## Security Best Practices

### 1. Code Security

```bash
# Pre-commit hook to prevent secrets
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Patterns to detect
PATTERNS=(
    "sk-[a-zA-Z0-9]{48}"           # Anthropic
    "sk-[a-zA-Z0-9]{48}"           # OpenAI
    "ghp_[a-zA-Z0-9]{36}"          # GitHub
    "AKIA[0-9A-Z]{16}"             # AWS Access Key
    "(?i)api[_-]?key"              # Generic API key
    "(?i)secret"                   # Generic secret
    "(?i)password"                 # Password
)

# Check staged files
for pattern in "${PATTERNS[@]}"; do
    if git diff --staged --name-only -z | \
       xargs -0 grep -E "$pattern" > /dev/null; then
        echo "Error: Possible secret detected!"
        echo "Pattern: $pattern"
        echo "Please remove secrets before committing."
        exit 1
    fi
done
EOF

chmod +x .git/hooks/pre-commit
```

### 2. File Permissions

```bash
# Secure file permissions
chmod 600 ~/.ssh/jonathon_*        # SSH keys
chmod 600 ~/.jonathon/secrets/*    # Secret files
chmod 700 ~/.jonathon              # Secrets directory
chmod 644 ~/.jonathon/config/*     # Config files
```

### 3. Audit and Monitoring

```bash
# Check for exposed secrets in git history
brew install git-secrets
git secrets --install
git secrets --register-aws

# Scan repository
git secrets --scan

# Check file permissions
find ~/.jonathon -type f -exec ls -l {} \; | \
    awk '$1 !~ /^-rw-------/ { print "Insecure:", $NF }'
```

## Emergency Procedures

### 1. Compromised API Key

```bash
#!/bin/bash
# Emergency key rotation script

echo "⚠️  EMERGENCY: API Key Compromise Response"
echo "========================================="

# 1. Revoke compromised keys immediately
echo "1. Revoke keys in provider console:"
echo "   - Anthropic: https://console.anthropic.com"
echo "   - OpenAI: https://platform.openai.com"
echo "   - GitHub: https://github.com/settings/tokens"

# 2. Generate new keys
echo "2. Generate new keys in each console"

# 3. Update all systems
echo "3. Updating stored secrets..."

# Update AWS Secrets Manager
read -s -p "New Anthropic API Key: " new_anthropic_key
aws secretsmanager update-secret \
    --secret-id "jonathon/anthropic-api-key" \
    --secret-string "$new_anthropic_key"

# 4. Audit access logs
echo "4. Check access logs for unauthorized usage"

# 5. Notify team
echo "5. Notify team members of key rotation"
```

### 2. Incident Response Checklist

- [ ] Identify compromised credential
- [ ] Revoke access immediately
- [ ] Generate new credentials
- [ ] Update all systems using the credential
- [ ] Audit logs for unauthorized access
- [ ] Document incident and timeline
- [ ] Review and improve security practices
- [ ] Notify affected parties if required

### 3. Regular Security Audits

```bash
# Monthly security audit script
cat > ~/.jonathon/scripts/security-audit.sh << 'EOF'
#!/bin/bash

echo "Jonathon Security Audit"
echo "======================"
date

# Check for old API keys
echo -e "\n1. Checking API key age..."
# Add logic to check key creation dates

# Check file permissions
echo -e "\n2. Checking file permissions..."
find ~/.jonathon -type f -name "*.env*" -exec ls -l {} \;

# Check for secrets in code
echo -e "\n3. Scanning for exposed secrets..."
git secrets --scan

# Check SSH key strength
echo -e "\n4. Checking SSH keys..."
for key in ~/.ssh/jonathon_*; do
    if [[ -f "$key" && ! "$key" =~ \.pub$ ]]; then
        ssh-keygen -l -f "$key"
    fi
done

# Check for unused credentials
echo -e "\n5. Review unused credentials..."
echo "   - Check AWS IAM for unused access keys"
echo "   - Review GitHub personal access tokens"
echo "   - Audit API key usage in provider dashboards"

echo -e "\nAudit complete. Review findings above."
EOF

chmod +x ~/.jonathon/scripts/security-audit.sh
```

## Quick Reference Card

### Common Commands

```bash
# Load all secrets
source ~/.jonathon/scripts/load-secrets.sh

# Test API key
curl -H "x-api-key: $ANTHROPIC_API_KEY" \
     -H "anthropic-version: 2023-06-01" \
     https://api.anthropic.com/v1/models

# Rotate AWS credentials
aws-vault rotate jonathon

# Generate secure password
openssl rand -base64 32

# Encrypt file
openssl enc -aes-256-cbc -salt -pbkdf2 -in file.txt -out file.enc

# Decrypt file
openssl enc -aes-256-cbc -d -pbkdf2 -in file.enc -out file.txt
```

### Security Checklist

Daily:
- [ ] Use latest security patches
- [ ] Lock screen when away
- [ ] Use VPN on public WiFi

Weekly:
- [ ] Review access logs
- [ ] Check for security updates
- [ ] Backup encrypted secrets

Monthly:
- [ ] Rotate API keys
- [ ] Run security audit
- [ ] Review IAM permissions
- [ ] Update passwords

## Resources

- [OWASP Security Guidelines](https://owasp.org)
- [AWS Security Best Practices](https://aws.amazon.com/security/)
- [GitHub Security](https://docs.github.com/en/code-security)
- [macOS Security Guide](https://support.apple.com/guide/security/)