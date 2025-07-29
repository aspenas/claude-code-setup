#!/bin/bash
# Deploy Documentation to docs.candlefish.ai
# Author: Patrick Smith (patrick@candlefish.ai)
# This script deploys the documentation to a Netlify subdomain

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Configuration
DOCS_SOURCE_DIR="$HOME/candlefish-ai/projects/jonathon/docs"
DOCS_BUILD_DIR="$HOME/candlefish-ai/projects/jonathon/docs-site"
SITE_NAME="candlefish-claude-docs"
CUSTOM_DOMAIN="docs.candlefish.ai"

# Check if Netlify CLI is installed
check_netlify_cli() {
    if ! command -v netlify &> /dev/null; then
        log "Installing Netlify CLI..."
        npm install -g netlify-cli
    else
        info "Netlify CLI is already installed"
    fi
}

# Create the documentation site structure
create_docs_site() {
    log "Creating documentation site structure..."
    
    # Create build directory
    rm -rf "$DOCS_BUILD_DIR"
    mkdir -p "$DOCS_BUILD_DIR"/{css,js,img}
    
    # Create index.html
    cat > "$DOCS_BUILD_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jonathon's Claude Code Setup - Candlefish AI</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <header>
        <nav>
            <div class="container">
                <h1>Claude Code Setup Documentation</h1>
                <p>By Candlefish AI</p>
            </div>
        </nav>
    </header>
    
    <main>
        <div class="container">
            <section class="hero">
                <h2>Complete Claude Code Development Environment</h2>
                <p>Everything you need to set up a professional AI development environment</p>
            </section>
            
            <section class="docs-list">
                <h3>Documentation</h3>
                <ul>
                    <li><a href="complete-setup-guide.html">Complete Setup Guide</a></li>
                    <li><a href="security-guide.html">Security & Credentials Guide</a></li>
                    <li><a href="quick-reference.html">Quick Reference</a></li>
                    <li><a href="aws-setup.html">AWS Setup Guide</a></li>
                    <li><a href="project-templates.html">Project Templates</a></li>
                </ul>
            </section>
            
            <section class="quick-start">
                <h3>Quick Start</h3>
                <pre><code># 1. Download the setup package
git clone https://github.com/candlefish-ai/claude-setup.git
cd claude-setup

# 2. Run the master setup script
./scripts/master-setup.sh

# 3. Start Claude Code
claude</code></pre>
            </section>
        </div>
    </main>
    
    <footer>
        <div class="container">
            <p>&copy; 2025 Candlefish AI. Contact: <a href="mailto:patrick@candlefish.ai">patrick@candlefish.ai</a></p>
        </div>
    </footer>
</body>
</html>
EOF

    # Create CSS
    cat > "$DOCS_BUILD_DIR/css/style.css" << 'EOF'
/* Candlefish AI Documentation Styles */
:root {
    --primary-color: #0066cc;
    --secondary-color: #00a8ff;
    --text-color: #333;
    --bg-color: #f8f9fa;
    --white: #ffffff;
    --code-bg: #f4f4f4;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: var(--text-color);
    background-color: var(--bg-color);
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}

header {
    background-color: var(--white);
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    padding: 1rem 0;
}

header h1 {
    color: var(--primary-color);
    font-size: 1.8rem;
}

header p {
    color: #666;
    font-size: 0.9rem;
}

main {
    padding: 2rem 0;
}

.hero {
    text-align: center;
    padding: 3rem 0;
    background-color: var(--white);
    border-radius: 8px;
    margin-bottom: 2rem;
}

.hero h2 {
    color: var(--primary-color);
    font-size: 2.5rem;
    margin-bottom: 1rem;
}

.docs-list {
    background-color: var(--white);
    padding: 2rem;
    border-radius: 8px;
    margin-bottom: 2rem;
}

.docs-list h3 {
    color: var(--primary-color);
    margin-bottom: 1rem;
}

.docs-list ul {
    list-style: none;
}

.docs-list li {
    padding: 0.5rem 0;
}

.docs-list a {
    color: var(--secondary-color);
    text-decoration: none;
    font-size: 1.1rem;
}

.docs-list a:hover {
    text-decoration: underline;
}

.quick-start {
    background-color: var(--white);
    padding: 2rem;
    border-radius: 8px;
}

.quick-start h3 {
    color: var(--primary-color);
    margin-bottom: 1rem;
}

pre {
    background-color: var(--code-bg);
    padding: 1rem;
    border-radius: 4px;
    overflow-x: auto;
}

code {
    font-family: 'Courier New', Courier, monospace;
    font-size: 0.9rem;
}

footer {
    background-color: var(--white);
    padding: 2rem 0;
    margin-top: 3rem;
    text-align: center;
    border-top: 1px solid #eee;
}

footer a {
    color: var(--primary-color);
    text-decoration: none;
}

@media (max-width: 768px) {
    .hero h2 {
        font-size: 2rem;
    }
}
EOF

    # Convert markdown files to HTML
    log "Converting documentation to HTML..."
    
    # Function to convert markdown to simple HTML
    convert_md_to_html() {
        local md_file="$1"
        local html_file="$2"
        local title="$3"
        
        cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title - Candlefish AI</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .doc-content {
            background-color: white;
            padding: 2rem;
            border-radius: 8px;
            max-width: 900px;
            margin: 0 auto;
        }
        .doc-content h1, .doc-content h2, .doc-content h3 {
            color: var(--primary-color);
            margin-top: 2rem;
            margin-bottom: 1rem;
        }
        .doc-content h1 { font-size: 2rem; }
        .doc-content h2 { font-size: 1.5rem; }
        .doc-content h3 { font-size: 1.2rem; }
        .doc-content pre {
            background-color: #f4f4f4;
            padding: 1rem;
            border-radius: 4px;
            overflow-x: auto;
            margin: 1rem 0;
        }
        .doc-content code {
            background-color: #f4f4f4;
            padding: 0.2rem 0.4rem;
            border-radius: 3px;
            font-size: 0.9rem;
        }
        .doc-content pre code {
            background-color: transparent;
            padding: 0;
        }
        .doc-content ul, .doc-content ol {
            margin-left: 2rem;
            margin-bottom: 1rem;
        }
        .doc-content p {
            margin-bottom: 1rem;
        }
        .back-link {
            display: inline-block;
            margin-bottom: 2rem;
            color: var(--primary-color);
            text-decoration: none;
        }
    </style>
</head>
<body>
    <header>
        <nav>
            <div class="container">
                <h1>Claude Code Setup Documentation</h1>
                <p>By Candlefish AI</p>
            </div>
        </nav>
    </header>
    
    <main>
        <div class="container">
            <a href="index.html" class="back-link">← Back to Documentation</a>
            <div class="doc-content">
EOF
        
        # Simple markdown to HTML conversion
        # This is a basic conversion - in production, use a proper markdown parser
        sed -e 's/^# \(.*\)$/<h1>\1<\/h1>/' \
            -e 's/^## \(.*\)$/<h2>\1<\/h2>/' \
            -e 's/^### \(.*\)$/<h3>\1<\/h3>/' \
            -e 's/```bash/<pre><code class="language-bash">/' \
            -e 's/```typescript/<pre><code class="language-typescript">/' \
            -e 's/```javascript/<pre><code class="language-javascript">/' \
            -e 's/```yaml/<pre><code class="language-yaml">/' \
            -e 's/```json/<pre><code class="language-json">/' \
            -e 's/```/<\/code><\/pre>/' \
            -e 's/`\([^`]*\)`/<code>\1<\/code>/g' \
            -e 's/^\* /<li>/' \
            -e 's/^[0-9]\+\. /<li>/' \
            -e 's/^$/<\/p><p>/' \
            "$md_file" >> "$html_file"
        
        cat >> "$html_file" << EOF
            </div>
        </div>
    </main>
    
    <footer>
        <div class="container">
            <p>&copy; 2025 Candlefish AI. Contact: <a href="mailto:patrick@candlefish.ai">patrick@candlefish.ai</a></p>
        </div>
    </footer>
</body>
</html>
EOF
    }
    
    # Convert all documentation files
    convert_md_to_html "$DOCS_SOURCE_DIR/COMPLETE_SETUP_GUIDE.md" "$DOCS_BUILD_DIR/complete-setup-guide.html" "Complete Setup Guide"
    convert_md_to_html "$DOCS_SOURCE_DIR/SECURITY_AND_CREDENTIALS_GUIDE.md" "$DOCS_BUILD_DIR/security-guide.html" "Security & Credentials Guide"
    convert_md_to_html "$DOCS_SOURCE_DIR/QUICK_REFERENCE.md" "$DOCS_BUILD_DIR/quick-reference.html" "Quick Reference"
    
    # Create additional pages
    echo "<h1>AWS Setup Guide</h1><p>Coming soon...</p>" > "$DOCS_BUILD_DIR/aws-setup.html"
    echo "<h1>Project Templates</h1><p>Coming soon...</p>" > "$DOCS_BUILD_DIR/project-templates.html"
    
    # Create netlify.toml for configuration
    cat > "$DOCS_BUILD_DIR/netlify.toml" << EOF
[build]
  publish = "."

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    X-XSS-Protection = "1; mode=block"

[[redirects]]
  from = "https://candlefish-claude-docs.netlify.app/*"
  to = "https://docs.candlefish.ai/:splat"
  status = 301
  force = true
EOF
    
    log "Documentation site created successfully"
}

# Deploy to Netlify
deploy_to_netlify() {
    log "Deploying to Netlify..."
    
    cd "$DOCS_BUILD_DIR"
    
    # Initialize Netlify site if not exists
    if [ ! -f ".netlify/state.json" ]; then
        log "Initializing new Netlify site..."
        netlify init --manual
        
        # Link to existing site or create new one
        netlify link --name "$SITE_NAME"
    fi
    
    # Deploy the site
    netlify deploy --prod --dir . --message "Updated documentation $(date)"
    
    # Set custom domain if not already set
    info "Setting custom domain to $CUSTOM_DOMAIN"
    netlify domains:add "$CUSTOM_DOMAIN" || true
    
    log "Deployment complete!"
    info "Documentation available at: https://$CUSTOM_DOMAIN"
}

# Main execution
main() {
    echo -e "${BLUE}Deploying Documentation to Netlify${NC}"
    echo -e "${BLUE}==================================${NC}"
    echo
    
    check_netlify_cli
    create_docs_site
    deploy_to_netlify
    
    echo
    echo -e "${GREEN}✅ Documentation deployed successfully!${NC}"
    echo
    echo "Next steps:"
    echo "1. Ensure DNS for docs.candlefish.ai points to Netlify"
    echo "2. Enable HTTPS in Netlify dashboard"
    echo "3. Test the live site at https://docs.candlefish.ai"
    echo
}

# Run main function
main "$@"