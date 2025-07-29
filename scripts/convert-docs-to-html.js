#!/usr/bin/env node
/**
 * Convert Markdown Documentation to Candlefish AI Styled HTML
 * Author: Patrick Smith (patrick@candlefish.ai)
 */

const fs = require('fs');
const path = require('path');

// HTML template for documentation pages
const htmlTemplate = (title, content) => `<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title} - Candlefish AI Documentation</title>
    <meta name="description" content="${title} for Claude Code development environment">
    <meta property="og:title" content="${title} - Candlefish AI">
    <meta property="og:image" content="https://candlefish.ai/logo/candlefish_highquality.png">
    <link rel="canonical" href="https://docs.candlefish.ai">
    
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Berkeley+Mono&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
    
    <style>
        /* Base styles from main site */
        *, *::before, *::after {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        
        :root {
            --grid: 8px;
            --container-max: 900px;
            --color-black: #000000;
            --color-white: #FFFFFF;
            --color-teal: #00CED1;
            --color-teal-dark: #00A5A8;
            --color-gray-100: #0A0A0A;
            --color-gray-200: #1A1A1A;
            --color-gray-300: #2A2A2A;
            --color-gray-400: #3A3A3A;
            --color-gray-600: #8A8A8A;
            --color-gray-700: #AAAAAA;
            --font-mono: 'Berkeley Mono', 'Courier New', monospace;
            --font-sans: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        }
        
        [data-theme="dark"] {
            --bg-primary: var(--color-black);
            --bg-secondary: var(--color-gray-100);
            --bg-tertiary: var(--color-gray-200);
            --text-primary: var(--color-white);
            --text-secondary: var(--color-gray-700);
            --text-tertiary: var(--color-gray-600);
            --border-color: var(--color-gray-400);
            --accent: var(--color-teal);
        }
        
        body {
            font-family: var(--font-sans);
            font-size: 16px;
            line-height: 1.6;
            color: var(--text-primary);
            background-color: var(--bg-primary);
            min-height: 100vh;
        }
        
        /* Navigation */
        .nav {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            z-index: 1000;
            padding: calc(var(--grid) * 3) 0;
            background: rgba(0, 0, 0, 0.95);
            backdrop-filter: blur(10px);
            border-bottom: 1px solid var(--border-color);
        }
        
        .nav__container {
            max-width: var(--container-max);
            margin: 0 auto;
            padding: 0 calc(var(--grid) * 3);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .nav__logo {
            display: flex;
            align-items: center;
            gap: calc(var(--grid) * 2);
            text-decoration: none;
            color: var(--text-primary);
        }
        
        .nav__logo img {
            width: 40px;
            height: 40px;
        }
        
        /* Main content */
        .doc-container {
            max-width: var(--container-max);
            margin: 0 auto;
            padding: calc(var(--grid) * 15) calc(var(--grid) * 3);
            min-height: 100vh;
        }
        
        .doc-header {
            margin-bottom: calc(var(--grid) * 6);
            padding-bottom: calc(var(--grid) * 4);
            border-bottom: 1px solid var(--border-color);
        }
        
        .doc-title {
            font-size: 3rem;
            font-weight: 300;
            letter-spacing: -0.02em;
            margin-bottom: calc(var(--grid) * 2);
        }
        
        .doc-meta {
            color: var(--text-secondary);
            font-size: 0.875rem;
        }
        
        /* Content styles */
        .doc-content h1 {
            font-size: 2.5rem;
            font-weight: 300;
            margin: calc(var(--grid) * 6) 0 calc(var(--grid) * 3) 0;
            color: var(--accent);
        }
        
        .doc-content h2 {
            font-size: 2rem;
            font-weight: 400;
            margin: calc(var(--grid) * 5) 0 calc(var(--grid) * 2) 0;
        }
        
        .doc-content h3 {
            font-size: 1.5rem;
            font-weight: 500;
            margin: calc(var(--grid) * 4) 0 calc(var(--grid) * 2) 0;
        }
        
        .doc-content h4 {
            font-size: 1.25rem;
            font-weight: 500;
            margin: calc(var(--grid) * 3) 0 calc(var(--grid) * 2) 0;
        }
        
        .doc-content p {
            margin-bottom: calc(var(--grid) * 2);
            color: var(--text-secondary);
        }
        
        .doc-content ul, .doc-content ol {
            margin: 0 0 calc(var(--grid) * 3) calc(var(--grid) * 3);
            color: var(--text-secondary);
        }
        
        .doc-content li {
            margin-bottom: calc(var(--grid) * 1);
        }
        
        .doc-content code {
            font-family: var(--font-mono);
            font-size: 0.875rem;
            background: var(--bg-tertiary);
            padding: 2px 6px;
            border-radius: 4px;
            color: var(--accent);
        }
        
        .doc-content pre {
            background: var(--bg-tertiary);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: calc(var(--grid) * 3);
            margin: calc(var(--grid) * 3) 0;
            overflow-x: auto;
        }
        
        .doc-content pre code {
            background: none;
            padding: 0;
            color: var(--text-primary);
            display: block;
            line-height: 1.6;
        }
        
        .doc-content blockquote {
            border-left: 4px solid var(--accent);
            padding-left: calc(var(--grid) * 3);
            margin: calc(var(--grid) * 3) 0;
            color: var(--text-secondary);
            font-style: italic;
        }
        
        .doc-content a {
            color: var(--accent);
            text-decoration: none;
            border-bottom: 1px solid transparent;
            transition: border-color 0.2s;
        }
        
        .doc-content a:hover {
            border-bottom-color: var(--accent);
        }
        
        .doc-content table {
            width: 100%;
            border-collapse: collapse;
            margin: calc(var(--grid) * 3) 0;
        }
        
        .doc-content th, .doc-content td {
            padding: calc(var(--grid) * 2);
            border: 1px solid var(--border-color);
            text-align: left;
        }
        
        .doc-content th {
            background: var(--bg-tertiary);
            font-weight: 500;
        }
        
        /* Back to docs link */
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: calc(var(--grid) * 1);
            color: var(--text-secondary);
            text-decoration: none;
            margin-bottom: calc(var(--grid) * 4);
            transition: color 0.2s;
        }
        
        .back-link:hover {
            color: var(--accent);
        }
        
        /* Footer */
        .footer {
            margin-top: calc(var(--grid) * 10);
            padding-top: calc(var(--grid) * 4);
            border-top: 1px solid var(--border-color);
            text-align: center;
            color: var(--text-tertiary);
            font-size: 0.875rem;
        }
        
        .footer a {
            color: var(--accent);
            text-decoration: none;
        }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav class="nav">
        <div class="nav__container">
            <a href="index.html" class="nav__logo">
                <img src="https://candlefish.ai/logo/candlefish_highquality.webp" alt="Candlefish AI">
                <span>Documentation</span>
            </a>
        </div>
    </nav>
    
    <!-- Main Content -->
    <div class="doc-container">
        <a href="index.html" class="back-link">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 12H5M12 19l-7-7 7-7"/>
            </svg>
            Back to Documentation
        </a>
        
        <header class="doc-header">
            <h1 class="doc-title">${title}</h1>
            <div class="doc-meta">By Patrick Smith (patrick@candlefish.ai) - Candlefish AI</div>
        </header>
        
        <div class="doc-content">
            ${content}
        </div>
        
        <footer class="footer">
            <p>&copy; 2025 Candlefish AI LLC | <a href="https://candlefish.ai">candlefish.ai</a></p>
        </footer>
    </div>
</body>
</html>`;

// Simple markdown to HTML converter
function convertMarkdownToHTML(markdown) {
    let html = markdown;
    
    // Headers
    html = html.replace(/^#### (.*$)/gim, '<h4>$1</h4>');
    html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
    html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
    html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');
    
    // Bold and italic
    html = html.replace(/\*\*\*(.*?)\*\*\*/g, '<strong><em>$1</em></strong>');
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/\*(.*?)\*/g, '<em>$1</em>');
    
    // Links
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
    
    // Inline code
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
    
    // Code blocks
    html = html.replace(/```(\w+)?\n([\s\S]*?)```/g, (match, lang, code) => {
        return `<pre><code class="language-${lang || 'text'}">${escapeHtml(code.trim())}</code></pre>`;
    });
    
    // Lists
    html = html.replace(/^\* (.+)$/gim, '<li>$1</li>');
    html = html.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>');
    html = html.replace(/^\d+\. (.+)$/gim, '<li>$1</li>');
    
    // Paragraphs
    html = html.split('\n\n').map(para => {
        if (!para.startsWith('<') && para.trim()) {
            return `<p>${para}</p>`;
        }
        return para;
    }).join('\n\n');
    
    // Blockquotes
    html = html.replace(/^> (.+)$/gim, '<blockquote>$1</blockquote>');
    
    return html;
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

// Document mappings
const documents = [
    {
        input: '../docs/COMPLETE_SETUP_GUIDE.md',
        output: '../docs-site/complete-setup-guide.html',
        title: 'Complete Setup Guide'
    },
    {
        input: '../docs/SECURITY_AND_CREDENTIALS_GUIDE.md',
        output: '../docs-site/security-guide.html',
        title: 'Security & Credentials Guide'
    },
    {
        input: '../docs/QUICK_REFERENCE.md',
        output: '../docs-site/quick-reference.html',
        title: 'Quick Reference'
    }
];

// Additional pages with custom content
const additionalPages = [
    {
        output: '../docs-site/aws-setup.html',
        title: 'AWS Setup Guide',
        content: `
            <h2>Complete AWS Setup Guide</h2>
            <p>This guide covers setting up your AWS infrastructure for Claude Code development.</p>
            <h3>Prerequisites</h3>
            <ul>
                <li>AWS Account (we'll create one together)</li>
                <li>Basic understanding of cloud concepts</li>
                <li>Completed the main setup guide</li>
            </ul>
            <h3>Quick Start</h3>
            <pre><code class="language-bash"># Run the AWS setup script
./scripts/aws-complete-setup.sh

# Follow the prompts to configure:
# - IAM users and permissions
# - S3 buckets for storage
# - Secrets Manager for API keys
# - DynamoDB for session storage</code></pre>
            <p>For detailed instructions, refer to the Complete Setup Guide.</p>
        `
    },
    {
        output: '../docs-site/project-templates.html',
        title: 'Project Templates',
        content: `
            <h2>Production-Ready Project Templates</h2>
            <p>Candlefish AI provides battle-tested templates for quick project setup.</p>
            <h3>Available Templates</h3>
            <h4>Next.js + TypeScript + AI</h4>
            <pre><code class="language-bash">./templates/create-candlefish-project.sh my-app</code></pre>
            <p>Features:</p>
            <ul>
                <li>Next.js 14 with App Router</li>
                <li>TypeScript with strict mode</li>
                <li>Multi-provider AI service (Anthropic + OpenAI)</li>
                <li>Authentication with API key management</li>
                <li>Rate limiting and monitoring</li>
                <li>Prisma ORM with PostgreSQL</li>
            </ul>
            <h4>Python FastAPI</h4>
            <pre><code class="language-bash">./templates/create-python-project.sh my-api</code></pre>
            <p>Coming soon with similar enterprise features.</p>
        `
    },
    {
        output: '../docs-site/troubleshooting.html',
        title: 'Troubleshooting Guide',
        content: `
            <h2>Troubleshooting Common Issues</h2>
            <h3>Claude Code Issues</h3>
            <h4>Command not found: claude</h4>
            <pre><code class="language-bash"># Reload your shell configuration
source ~/.zshrc

# Check if claude is in PATH
which claude

# Reinstall if needed
npm install -g @anthropic-ai/claude-code@latest</code></pre>
            
            <h4>API Key Issues</h4>
            <pre><code class="language-bash"># Test your API key
curl -H "x-api-key: $ANTHROPIC_API_KEY" \\
     -H "anthropic-version: 2023-06-01" \\
     https://api.anthropic.com/v1/models</code></pre>
            
            <h3>Port Conflicts</h3>
            <pre><code class="language-bash"># Find process using port 3000
lsof -ti:3000

# Kill the process
lsof -ti:3000 | xargs kill -9</code></pre>
            
            <h3>Node/npm Issues</h3>
            <pre><code class="language-bash"># Clear npm cache
npm cache clean --force

# Remove node_modules and reinstall
rm -rf node_modules package-lock.json
npm install</code></pre>
        `
    }
];

// Convert all documents
console.log('Converting documentation to HTML...');

// Ensure output directory exists
const docsDir = path.join(__dirname, '../docs-site');
if (!fs.existsSync(docsDir)) {
    fs.mkdirSync(docsDir, { recursive: true });
}

// Convert markdown files
documents.forEach(doc => {
    const inputPath = path.join(__dirname, doc.input);
    const outputPath = path.join(__dirname, doc.output);
    
    if (fs.existsSync(inputPath)) {
        const markdown = fs.readFileSync(inputPath, 'utf8');
        const htmlContent = convertMarkdownToHTML(markdown);
        const fullHTML = htmlTemplate(doc.title, htmlContent);
        
        fs.writeFileSync(outputPath, fullHTML);
        console.log(`✓ Converted ${doc.title}`);
    } else {
        console.warn(`⚠ Source file not found: ${inputPath}`);
    }
});

// Create additional pages
additionalPages.forEach(page => {
    const outputPath = path.join(__dirname, page.output);
    const fullHTML = htmlTemplate(page.title, page.content);
    
    fs.writeFileSync(outputPath, fullHTML);
    console.log(`✓ Created ${page.title}`);
});

// Copy logo
const logoDir = path.join(docsDir, 'logo');
if (!fs.existsSync(logoDir)) {
    fs.mkdirSync(logoDir, { recursive: true });
}

console.log('\n✅ Documentation conversion complete!');
console.log(`Files created in: ${docsDir}`);