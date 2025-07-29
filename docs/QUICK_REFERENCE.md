# Jonathon's Quick Reference Guide

*By Patrick Smith (patrick@candlefish.ai) - Candlefish AI*

## Claude Code Commands

### Basic Usage
```bash
c                          # Start Claude Code (alias)
claude                     # Start Claude Code
claude-max                 # Max context (200k tokens)
claude-think              # Step-by-step thinking mode
claude-code               # Full command

# With options
claude --model claude-opus-4-20250514
claude --context 100k
claude --thinking
claude --verbose
```

### Project Navigation
```bash
claude-project myapp       # Open project in Claude
claude --cwd ./path       # Specific directory
cd ~/projects && claude   # Navigate then start
```

## Essential Terminal Commands

### File Operations
```bash
ls -la                    # List all files with details
cd ~/projects             # Change directory
mkdir -p path/to/dir      # Create nested directories
touch filename.txt        # Create empty file
rm -rf directory          # Remove directory (careful!)
cp -r source dest         # Copy recursively
mv old new               # Move/rename
```

### Git Essentials
```bash
git init                  # Initialize repository
git add .                 # Stage all changes
git commit -m "message"   # Commit with message
git push origin main      # Push to remote
git pull                  # Pull latest changes
git status               # Check status
git log --oneline        # View commit history
git checkout -b feature  # Create new branch
```

### Process Management
```bash
ps aux | grep node       # Find Node processes
kill -9 PID             # Force kill process
lsof -i :3000           # Find process on port
pkill -f "node"         # Kill by name pattern
top                     # System monitor
htop                    # Better system monitor
```

## Development Workflows

### Start New Project
```bash
# Next.js + TypeScript
~/.claude/templates/create-nextjs-project.sh myapp

# Python FastAPI
~/.claude/templates/create-python-project.sh myapi

# From Candlefish template
~/candlefish-ai/projects/jonathon/templates/create-candlefish-project.sh myproject
```

### Daily Development
```bash
# 1. Load secrets
source ~/.jonathon/scripts/load-secrets.sh

# 2. Start project
cd ~/projects/myapp
pnpm dev

# 3. Open Claude in project
claude

# 4. Run tests
pnpm test
```

### Database Operations
```bash
# Prisma
pnpm prisma migrate dev   # Run migrations
pnpm prisma studio       # Visual database editor
pnpm prisma generate     # Generate client

# PostgreSQL
psql -U user -d database # Connect to database
pg_dump database > backup.sql
```

## API Testing

### cURL Examples
```bash
# GET request
curl https://api.example.com/users

# POST with JSON
curl -X POST https://api.example.com/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"name": "John", "email": "john@example.com"}'

# With output formatting
curl -s https://api.example.com/data | jq '.'
```

### HTTPie (easier syntax)
```bash
# GET
http GET api.example.com/users

# POST
http POST api.example.com/users \
  name="John" email="john@example.com" \
  "Authorization: Bearer $API_KEY"
```

## AWS Commands

### Basic AWS CLI
```bash
# Configure
aws configure

# S3
aws s3 ls                        # List buckets
aws s3 cp file.txt s3://bucket/  # Upload file
aws s3 sync . s3://bucket/path/  # Sync directory

# Secrets Manager
aws secretsmanager get-secret-value --secret-id "name"
aws secretsmanager create-secret --name "name" --secret-string "value"

# IAM
aws iam create-user --user-name username
aws iam create-access-key --user-name username
```

### AWS Vault
```bash
aws-vault add profile         # Add credentials
aws-vault exec profile -- cmd # Run with credentials
aws-vault list               # List profiles
aws-vault rotate profile     # Rotate credentials
```

## Environment Management

### Node.js / npm / pnpm
```bash
# Node version
nvm install 20              # Install Node v20
nvm use 20                 # Use Node v20
nvm alias default 20       # Set default

# Package management
pnpm install               # Install dependencies
pnpm add package          # Add dependency
pnpm add -D package       # Add dev dependency
pnpm run script           # Run package.json script
pnpm outdated            # Check for updates
```

### Python
```bash
# Virtual environment
python3 -m venv venv      # Create venv
source venv/bin/activate  # Activate venv
deactivate               # Deactivate venv

# Poetry
poetry init              # Initialize project
poetry add package       # Add dependency
poetry install           # Install all deps
poetry run python app.py # Run with poetry
```

## Security Quick Checks

### File Permissions
```bash
chmod 600 ~/.ssh/id_*     # Secure SSH keys
chmod 644 public_file     # Public readable
chmod 755 script.sh       # Executable script
chmod 700 private_dir     # Private directory
```

### Find Secrets
```bash
# Search for potential secrets
grep -r "api[_-]key" .
grep -r "password" .
grep -r "sk-" .          # API keys
git secrets --scan       # Git secrets scan
```

## Debugging

### Network
```bash
ping google.com          # Test connectivity
nslookup domain.com      # DNS lookup
dig domain.com           # Detailed DNS
curl -I https://site.com # Check headers
netstat -an | grep 3000  # Check port usage
```

### Logs
```bash
tail -f logfile.log      # Follow log file
tail -n 100 logfile.log  # Last 100 lines
grep ERROR logfile.log   # Find errors
journalctl -u service    # System service logs
```

## VS Code Shortcuts

### Navigation
```
Cmd+P         # Quick file open
Cmd+Shift+P   # Command palette
Cmd+B         # Toggle sidebar
Cmd+J         # Toggle terminal
Cmd+\         # Split editor
```

### Editing
```
Cmd+D         # Select next occurrence
Cmd+Shift+L   # Select all occurrences
Option+Up/Down # Move line up/down
Cmd+/         # Toggle comment
Cmd+Shift+[   # Fold code
```

### Terminal
```
Ctrl+`        # Toggle terminal
Cmd+K         # Clear terminal
Ctrl+C        # Cancel command
Ctrl+D        # Exit/EOF
```

## Docker Commands

### Basic
```bash
docker ps                 # List running containers
docker ps -a             # List all containers
docker images            # List images
docker logs container    # View logs
docker exec -it container bash # Enter container
```

### Compose
```bash
docker-compose up        # Start services
docker-compose down      # Stop services
docker-compose logs -f   # Follow logs
docker-compose ps        # List services
```

## Emergency Commands

### Port Already in Use
```bash
# Find and kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Alternative
npx kill-port 3000
```

### Clear npm/pnpm Cache
```bash
npm cache clean --force
pnpm store prune
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### Git Undo
```bash
git reset HEAD~1         # Undo last commit
git checkout -- file.txt # Discard changes
git clean -fd           # Remove untracked files
git stash              # Temporarily save changes
git stash pop          # Restore stashed changes
```

### System Resources
```bash
# Check disk space
df -h

# Check memory
free -h

# Find large files
find . -size +100M

# Clear space
brew cleanup
docker system prune -a
```

## Useful Aliases

Add to `~/.zshrc`:
```bash
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -la'
alias projects='cd ~/projects'

# Git
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline'

# Development
alias nr='npm run'
alias pr='pnpm run'
alias py='python3'
alias dc='docker-compose'

# Claude
alias c='claude'
alias cmax='claude-max'
alias cthink='claude-think'
```

## One-Liners

```bash
# Find and replace in files
find . -name "*.js" -exec sed -i '' 's/old/new/g' {} +

# Delete all node_modules
find . -name "node_modules" -type d -prune -exec rm -rf {} +

# List folder sizes
du -sh */ | sort -hr

# Watch command output
watch -n 2 'ps aux | grep node'

# Generate UUID
uuidgen | tr '[:upper:]' '[:lower:]'

# Pretty print JSON
echo '{"a":1}' | jq '.'

# Serve current directory
python3 -m http.server 8000

# Check weather
curl wttr.in/san-francisco
```

## Resources

### Documentation
- Claude API: https://docs.anthropic.com
- Next.js: https://nextjs.org/docs
- Prisma: https://www.prisma.io/docs
- AWS CLI: https://docs.aws.amazon.com/cli/

### Tools
- Regex101: https://regex101.com
- JWT.io: https://jwt.io
- Crontab Guru: https://crontab.guru
- ExplainShell: https://explainshell.com

### Learning
- Claude Cookbook: https://github.com/anthropics/anthropic-cookbook
- AWS Examples: https://github.com/aws-samples
- TypeScript Playground: https://www.typescriptlang.org/play