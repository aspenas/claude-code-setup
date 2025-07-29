# Jonathon's Claude Code Session Checklist

*By Patrick Smith (patrick@candlefish.ai) - Candlefish AI*

## Pre-Session Preparation (For Jonathon)

### Hardware
- [ ] MacBook (macOS 12.0 or later)
- [ ] Power adapter
- [ ] Stable internet connection
- [ ] External monitor (optional but helpful)

### Accounts to Create
- [ ] GitHub account (if not already)
- [ ] AWS account (we'll create together)
- [ ] Anthropic Console account (for API key)
- [ ] OpenAI account (optional)

### Downloads (Optional - we can do together)
- [ ] VS Code: https://code.visualstudio.com
- [ ] Docker Desktop: https://www.docker.com/products/docker-desktop

## Session Flow

### ⏰ Hour 1: Environment Setup
- [ ] Install Xcode Command Line Tools
- [ ] Install Homebrew
- [ ] Run master setup script
- [ ] Configure shell (zsh)

### ⏰ Hour 2: Core Tools
- [ ] Install Node.js via nvm
- [ ] Install essential CLI tools
- [ ] Set up Git configuration
- [ ] Create project directories

### ⏰ Hour 3: Claude Code Installation
- [ ] Install Claude Code package
- [ ] Configure Claude settings
- [ ] Create wrapper scripts
- [ ] Test Claude commands

### ⏰ Hour 4: Claude Code Practice
- [ ] Basic Claude usage
- [ ] Context window options
- [ ] Thinking mode
- [ ] Project navigation

### ⏰ Hour 5: AWS Account Setup
- [ ] Create AWS account
- [ ] Enable MFA
- [ ] Create IAM user
- [ ] Configure AWS CLI

### ⏰ Hour 6: AWS Automation
- [ ] Run AWS setup script
- [ ] Create S3 buckets
- [ ] Set up Secrets Manager
- [ ] Configure DynamoDB

### ⏰ Hour 7: Development Environment
- [ ] Install VS Code
- [ ] Add VS Code extensions
- [ ] Install PostgreSQL
- [ ] Set up Redis

### ⏰ Hour 8: First Project Creation
- [ ] Use Candlefish template
- [ ] Explore project structure
- [ ] Understand service architecture
- [ ] Run development server

### ⏰ Hour 9: API Integration
- [ ] Set up Anthropic API key
- [ ] Configure multi-provider AI
- [ ] Test API endpoints
- [ ] Implement rate limiting

### ⏰ Hour 10: Security Setup
- [ ] API key management
- [ ] Credential storage
- [ ] Security best practices
- [ ] Pre-commit hooks

### ⏰ Hour 11: Advanced Topics
- [ ] Performance optimization
- [ ] Debugging techniques
- [ ] Deployment preparation
- [ ] Monitoring setup

### ⏰ Hour 12: Review & Practice
- [ ] Common workflows
- [ ] Troubleshooting
- [ ] Q&A session
- [ ] Next steps planning

## Key Milestones

### ✅ By Hour 3
- Terminal configured
- Claude Code installed
- Basic commands working

### ✅ By Hour 6
- AWS account active
- Credentials secure
- Infrastructure created

### ✅ By Hour 9
- First project running
- API integration working
- Development flow understood

### ✅ By Hour 12
- Complete environment setup
- Security configured
- Ready for independent work

## Important Commands to Remember

```bash
# Start Claude
c

# Create new project
./templates/create-candlefish-project.sh myapp

# Load secrets
source ~/.jonathon/scripts/load-secrets.sh

# Start development
pnpm dev

# Run tests
pnpm test
```

## Success Criteria

By the end of the session, Jonathon should be able to:

1. **Use Claude Code effectively**
   - Start Claude in any project
   - Use different context modes
   - Navigate projects efficiently

2. **Manage AWS resources**
   - Access AWS console
   - Use AWS CLI
   - Manage secrets securely

3. **Create new projects**
   - Use project templates
   - Understand architecture
   - Implement AI features

4. **Follow security practices**
   - Store credentials safely
   - Use environment variables
   - Rotate keys when needed

5. **Debug common issues**
   - Fix port conflicts
   - Resolve npm errors
   - Check API connectivity

## Post-Session Resources

### Take Home
- All scripts in `~/candlefish-ai/projects/jonathon/`
- Documentation guides
- Quick reference sheet
- Support contact info

### Practice Projects
1. Build a simple AI chat interface
2. Create an API with authentication
3. Implement rate limiting
4. Add monitoring dashboard

### Continued Learning
- Claude Cookbook examples
- AWS tutorials
- TypeScript deep dive
- Security best practices

## Notes Section

Use this space to track:
- Questions that come up
- Customizations needed
- Issues encountered
- Ideas for projects

---

**Remember**: This is a comprehensive setup, but it's okay if we don't cover everything. The goal is to establish a solid foundation and provide resources for continued learning.

Good luck with your session! 🚀