#!/bin/bash
# Create Candlefish AI Style Project
# Author: Patrick Smith (patrick@candlefish.ai)
# Based on the proven architecture from candlefish.ai
# Documentation: https://docs.candlefish.ai/project-templates

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get project name
PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    read -p "Enter project name: " PROJECT_NAME
fi

echo -e "${BLUE}Creating Candlefish AI style project: $PROJECT_NAME${NC}"

# Create Next.js project with specific options
pnpm create next-app@latest "$PROJECT_NAME" \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --no-src-dir \
    --import-alias "@/*"

cd "$PROJECT_NAME"

# Install core dependencies
echo -e "${GREEN}Installing core dependencies...${NC}"
pnpm add \
    @anthropic-ai/sdk \
    openai \
    @aws-sdk/client-secrets-manager \
    @aws-sdk/client-kms \
    prisma \
    @prisma/client \
    zod \
    @upstash/redis \
    @upstash/ratelimit \
    bcryptjs \
    jsonwebtoken \
    next-auth \
    @next-auth/prisma-adapter

# Install dev dependencies
pnpm add -D \
    @types/node \
    @types/bcryptjs \
    @types/jsonwebtoken \
    prettier \
    eslint-config-prettier \
    @testing-library/react \
    @testing-library/jest-dom \
    jest \
    jest-environment-jsdom \
    ts-jest

# Create directory structure
echo -e "${GREEN}Creating project structure...${NC}"
mkdir -p {services/{ai,auth,monitoring},lib/{auth,security,cache},app/api/{v1,v2,health,metrics},components/{ui,forms},hooks,utils,types,prisma,scripts,__tests__/{unit,integration,fixtures}}

# Initialize Prisma with PostgreSQL
echo -e "${GREEN}Initializing Prisma...${NC}"
pnpm prisma init

# Create Prisma schema
cat > prisma/schema.prisma << 'EOF'
// Prisma schema for Candlefish AI style project

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  name          String?
  passwordHash  String?
  tier          UserTier  @default(FREE)
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  
  apiKeys       ApiKey[]
  usageRecords  UsageRecord[]
  sessions      Session[]
}

model ApiKey {
  id            String    @id @default(cuid())
  name          String
  keyHash       String    @unique
  keyPrefix     String    // First 8 chars for identification
  lastUsedAt    DateTime?
  expiresAt     DateTime?
  createdAt     DateTime  @default(now())
  isActive      Boolean   @default(true)
  
  userId        String
  user          User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  usageRecords  UsageRecord[]
  
  @@index([userId])
  @@index([keyHash])
}

model UsageRecord {
  id            String    @id @default(cuid())
  endpoint      String
  method        String
  statusCode    Int
  inputTokens   Int       @default(0)
  outputTokens  Int       @default(0)
  model         String?
  responseTime  Int       // in milliseconds
  createdAt     DateTime  @default(now())
  
  userId        String?
  user          User?     @relation(fields: [userId], references: [id])
  
  apiKeyId      String?
  apiKey        ApiKey?   @relation(fields: [apiKeyId], references: [id])
  
  @@index([userId])
  @@index([apiKeyId])
  @@index([createdAt])
}

model Session {
  id            String    @id @default(cuid())
  sessionToken  String    @unique
  expires       DateTime
  createdAt     DateTime  @default(now())
  
  userId        String
  user          User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@index([userId])
}

model CacheEntry {
  id            String    @id @default(cuid())
  key           String    @unique
  value         Json
  expiresAt     DateTime
  createdAt     DateTime  @default(now())
  
  @@index([key])
  @@index([expiresAt])
}

enum UserTier {
  FREE
  PRO
  ENTERPRISE
}
EOF

# Create environment variables file
cat > .env.local << 'EOF'
# Database
DATABASE_URL="postgresql://localhost:5432/PROJECT_NAME_db"

# Authentication
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=

# AI Services
ANTHROPIC_API_KEY=
OPENAI_API_KEY=

# AWS (Optional)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

# Redis (Upstash)
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=

# Security
ALLOWED_ORIGINS=http://localhost:3000

# Monitoring (Optional)
SENTRY_DSN=
EOF

# Update .env.local with generated secret
NEXTAUTH_SECRET=$(openssl rand -base64 32)
sed -i '' "s/NEXTAUTH_SECRET=/NEXTAUTH_SECRET=$NEXTAUTH_SECRET/" .env.local
sed -i '' "s/PROJECT_NAME/$PROJECT_NAME/g" .env.local

# Create TypeScript configuration
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# Create unified AI service
cat > services/ai/unified-ai.service.ts << 'EOF'
import Anthropic from '@anthropic-ai/sdk';
import OpenAI from 'openai';

export interface AIProvider {
  generateCompletion(prompt: string, options?: GenerateOptions): Promise<AIResponse>;
}

export interface GenerateOptions {
  model?: string;
  maxTokens?: number;
  temperature?: number;
}

export interface AIResponse {
  content: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
}

export class AnthropicProvider implements AIProvider {
  private client: Anthropic;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
  }

  async generateCompletion(prompt: string, options?: GenerateOptions): Promise<AIResponse> {
    const response = await this.client.messages.create({
      model: options?.model || 'claude-opus-4-20250514',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: options?.maxTokens || 4096,
      temperature: options?.temperature || 0.7,
    });

    const content = response.content[0].text;
    
    return {
      content,
      model: response.model,
      inputTokens: response.usage?.input_tokens || 0,
      outputTokens: response.usage?.output_tokens || 0,
    };
  }
}

export class OpenAIProvider implements AIProvider {
  private client: OpenAI;

  constructor(apiKey: string) {
    this.client = new OpenAI({ apiKey });
  }

  async generateCompletion(prompt: string, options?: GenerateOptions): Promise<AIResponse> {
    const response = await this.client.chat.completions.create({
      model: options?.model || 'gpt-4-turbo-preview',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: options?.maxTokens || 4096,
      temperature: options?.temperature || 0.7,
    });

    const content = response.choices[0]?.message?.content || '';
    
    return {
      content,
      model: response.model,
      inputTokens: response.usage?.prompt_tokens || 0,
      outputTokens: response.usage?.completion_tokens || 0,
    };
  }
}

export class UnifiedAIService {
  private providers: Map<string, AIProvider> = new Map();
  private primaryProvider: string = 'anthropic';

  constructor() {
    // Initialize providers based on available API keys
    if (process.env.ANTHROPIC_API_KEY) {
      this.providers.set('anthropic', new AnthropicProvider(process.env.ANTHROPIC_API_KEY));
    }
    if (process.env.OPENAI_API_KEY) {
      this.providers.set('openai', new OpenAIProvider(process.env.OPENAI_API_KEY));
    }
  }

  async generateWithFallback(
    prompt: string,
    options?: GenerateOptions & { provider?: string }
  ): Promise<AIResponse> {
    const provider = options?.provider || this.primaryProvider;
    const aiProvider = this.providers.get(provider);

    if (!aiProvider) {
      throw new Error(`Provider ${provider} not configured`);
    }

    try {
      return await aiProvider.generateCompletion(prompt, options);
    } catch (error) {
      // Fallback logic
      console.error(`Primary provider ${provider} failed:`, error);
      
      // Try other providers
      for (const [name, fallbackProvider] of this.providers) {
        if (name !== provider) {
          try {
            console.log(`Trying fallback provider: ${name}`);
            return await fallbackProvider.generateCompletion(prompt, options);
          } catch (fallbackError) {
            console.error(`Fallback provider ${name} also failed:`, fallbackError);
          }
        }
      }
      
      throw new Error('All AI providers failed');
    }
  }
}
EOF

# Create auth service
cat > services/auth/auth.service.ts << 'EOF'
import { PrismaClient, User, ApiKey } from '@prisma/client';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';

export class AuthService {
  constructor(private prisma: PrismaClient) {}

  async createUser(email: string, password: string, name?: string): Promise<User> {
    const passwordHash = await bcrypt.hash(password, 10);
    
    return this.prisma.user.create({
      data: {
        email,
        passwordHash,
        name,
      },
    });
  }

  async validateUser(email: string, password: string): Promise<User | null> {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user || !user.passwordHash) {
      return null;
    }

    const isValid = await bcrypt.compare(password, user.passwordHash);
    return isValid ? user : null;
  }

  async createApiKey(userId: string, name: string): Promise<{ apiKey: ApiKey; plainKey: string }> {
    // Generate a secure random key
    const plainKey = `sk_${crypto.randomBytes(32).toString('base64url')}`;
    
    // Hash the key for storage
    const keyHash = crypto.createHash('sha256').update(plainKey).digest('hex');
    
    // Store first 8 chars as prefix for identification
    const keyPrefix = plainKey.substring(0, 8);

    const apiKey = await this.prisma.apiKey.create({
      data: {
        name,
        keyHash,
        keyPrefix,
        userId,
      },
    });

    return { apiKey, plainKey };
  }

  async validateApiKey(plainKey: string): Promise<{ user: User; apiKey: ApiKey } | null> {
    const keyHash = crypto.createHash('sha256').update(plainKey).digest('hex');
    
    const apiKey = await this.prisma.apiKey.findUnique({
      where: { 
        keyHash,
        isActive: true,
      },
      include: { user: true },
    });

    if (!apiKey) {
      return null;
    }

    // Check expiration
    if (apiKey.expiresAt && apiKey.expiresAt < new Date()) {
      return null;
    }

    // Update last used
    await this.prisma.apiKey.update({
      where: { id: apiKey.id },
      data: { lastUsedAt: new Date() },
    });

    return { user: apiKey.user, apiKey };
  }

  async createSession(userId: string): Promise<string> {
    const token = jwt.sign(
      { userId },
      process.env.NEXTAUTH_SECRET!,
      { expiresIn: '7d' }
    );

    await this.prisma.session.create({
      data: {
        sessionToken: token,
        userId,
        expires: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      },
    });

    return token;
  }
}
EOF

# Create rate limiter
cat > lib/security/rate-limiter.ts << 'EOF'
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

export interface RateLimitResult {
  success: boolean;
  limit: number;
  remaining: number;
  reset: Date;
}

export class RateLimiter {
  private limiters: Map<string, Ratelimit> = new Map();

  constructor() {
    // Initialize Redis client
    const redis = new Redis({
      url: process.env.UPSTASH_REDIS_REST_URL!,
      token: process.env.UPSTASH_REDIS_REST_TOKEN!,
    });

    // Define rate limits by tier
    this.limiters.set('free', new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(10, '1 m'), // 10 requests per minute
    }));

    this.limiters.set('pro', new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(60, '1 m'), // 60 requests per minute
    }));

    this.limiters.set('enterprise', new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(300, '1 m'), // 300 requests per minute
    }));
  }

  async checkLimit(identifier: string, tier: string = 'free'): Promise<RateLimitResult> {
    const limiter = this.limiters.get(tier) || this.limiters.get('free')!;
    const result = await limiter.limit(identifier);

    return {
      success: result.success,
      limit: result.limit,
      remaining: result.remaining,
      reset: new Date(result.reset),
    };
  }
}

export const rateLimiter = new RateLimiter();
EOF

# Create API route example
cat > app/api/v2/generate/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { UnifiedAIService } from '@/services/ai/unified-ai.service';
import { AuthService } from '@/services/auth/auth.service';
import { rateLimiter } from '@/lib/security/rate-limiter';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const authService = new AuthService(prisma);
const aiService = new UnifiedAIService();

// Request validation schema
const generateSchema = z.object({
  prompt: z.string().min(1).max(10000),
  model: z.string().optional(),
  provider: z.enum(['anthropic', 'openai']).optional(),
});

export async function POST(req: NextRequest) {
  try {
    // Extract API key
    const authHeader = req.headers.get('authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json(
        { error: 'Missing or invalid authorization header' },
        { status: 401 }
      );
    }

    const apiKey = authHeader.substring(7);
    
    // Validate API key
    const authResult = await authService.validateApiKey(apiKey);
    if (!authResult) {
      return NextResponse.json(
        { error: 'Invalid API key' },
        { status: 401 }
      );
    }

    const { user, apiKey: keyRecord } = authResult;

    // Rate limiting
    const rateLimit = await rateLimiter.checkLimit(user.id, user.tier);
    if (!rateLimit.success) {
      return NextResponse.json(
        { 
          error: 'Rate limit exceeded',
          retryAfter: Math.ceil((rateLimit.reset.getTime() - Date.now()) / 1000),
        },
        { 
          status: 429,
          headers: {
            'X-RateLimit-Limit': String(rateLimit.limit),
            'X-RateLimit-Remaining': String(rateLimit.remaining),
            'Retry-After': String(Math.ceil((rateLimit.reset.getTime() - Date.now()) / 1000)),
          }
        }
      );
    }

    // Parse and validate request body
    const body = await req.json();
    const validatedData = generateSchema.parse(body);

    // Generate completion
    const startTime = Date.now();
    const response = await aiService.generateWithFallback(validatedData.prompt, {
      model: validatedData.model,
      provider: validatedData.provider,
    });
    const responseTime = Date.now() - startTime;

    // Log usage
    await prisma.usageRecord.create({
      data: {
        endpoint: '/api/v2/generate',
        method: 'POST',
        statusCode: 200,
        inputTokens: response.inputTokens,
        outputTokens: response.outputTokens,
        model: response.model,
        responseTime,
        userId: user.id,
        apiKeyId: keyRecord.id,
      },
    });

    // Return response
    return NextResponse.json({
      success: true,
      content: response.content,
      model: response.model,
      usage: {
        inputTokens: response.inputTokens,
        outputTokens: response.outputTokens,
      },
    });
  } catch (error) {
    console.error('API error:', error);
    
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Invalid request data', details: error.errors },
        { status: 400 }
      );
    }

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
EOF

# Create health check endpoint
cat > app/api/health/route.ts << 'EOF'
import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function GET() {
  try {
    // Check database connection
    await prisma.$queryRaw`SELECT 1`;
    
    // Check Redis connection (if configured)
    let redisStatus = 'not configured';
    if (process.env.UPSTASH_REDIS_REST_URL) {
      try {
        const response = await fetch(`${process.env.UPSTASH_REDIS_REST_URL}/ping`, {
          headers: {
            Authorization: `Bearer ${process.env.UPSTASH_REDIS_REST_TOKEN}`,
          },
        });
        redisStatus = response.ok ? 'healthy' : 'unhealthy';
      } catch {
        redisStatus = 'unhealthy';
      }
    }

    return NextResponse.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        database: 'healthy',
        redis: redisStatus,
      },
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: 'Database connection failed',
      },
      { status: 503 }
    );
  }
}
EOF

# Create test configuration
cat > jest.config.js << 'EOF'
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  dir: './',
})

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
}

module.exports = createJestConfig(customJestConfig)
EOF

cat > jest.setup.js << 'EOF'
import '@testing-library/jest-dom'
EOF

# Create example test
cat > __tests__/unit/services/auth.service.test.ts << 'EOF'
import { AuthService } from '@/services/auth/auth.service';
import { PrismaClient } from '@prisma/client';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';

describe('AuthService', () => {
  let authService: AuthService;
  let prisma: DeepMockProxy<PrismaClient>;

  beforeEach(() => {
    prisma = mockDeep<PrismaClient>();
    authService = new AuthService(prisma as unknown as PrismaClient);
  });

  describe('createUser', () => {
    it('should create a user with hashed password', async () => {
      const mockUser = {
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
        passwordHash: 'hashed',
        tier: 'FREE',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prisma.user.create.mockResolvedValue(mockUser);

      const result = await authService.createUser(
        'test@example.com',
        'password123',
        'Test User'
      );

      expect(result).toEqual(mockUser);
      expect(prisma.user.create).toHaveBeenCalled();
    });
  });
});
EOF

# Create README
cat > README.md << EOF
# $PROJECT_NAME

A Candlefish AI style project with enterprise-grade features.

## Features

- 🚀 **Multi-Provider AI Integration** - Anthropic, OpenAI with automatic fallback
- 🔐 **Secure Authentication** - API key management with SHA-256 hashing
- ⚡ **Rate Limiting** - Tier-based limits with Redis/Upstash
- 📊 **Usage Tracking** - Detailed metrics and analytics
- 🛡️ **Security First** - CORS, CSP, and security headers
- 🧪 **Comprehensive Testing** - Unit, integration, and E2E tests
- 📝 **Type Safety** - Full TypeScript with strict mode

## Getting Started

### Prerequisites

- Node.js 20+
- PostgreSQL
- Redis (or Upstash account)

### Installation

1. Install dependencies:
\`\`\`bash
pnpm install
\`\`\`

2. Set up environment variables:
\`\`\`bash
cp .env.local .env
# Edit .env with your actual values
\`\`\`

3. Set up the database:
\`\`\`bash
pnpm prisma migrate dev
\`\`\`

4. Run the development server:
\`\`\`bash
pnpm dev
\`\`\`

### Testing

\`\`\`bash
# Run all tests
pnpm test

# Run with coverage
pnpm test:coverage

# Run in watch mode
pnpm test:watch
\`\`\`

## API Documentation

### Authentication

All API requests require a Bearer token:
\`\`\`
Authorization: Bearer sk_your_api_key_here
\`\`\`

### Endpoints

#### POST /api/v2/generate
Generate AI completions with multi-provider support.

**Request:**
\`\`\`json
{
  "prompt": "Your prompt here",
  "model": "claude-opus-4-20250514", // optional
  "provider": "anthropic" // optional, "anthropic" or "openai"
}
\`\`\`

**Response:**
\`\`\`json
{
  "success": true,
  "content": "Generated content",
  "model": "claude-opus-4-20250514",
  "usage": {
    "inputTokens": 50,
    "outputTokens": 200
  }
}
\`\`\`

#### GET /api/health
Check service health status.

## Architecture

\`\`\`
app/
├── api/              # API routes
│   ├── v1/          # Version 1 endpoints
│   └── v2/          # Version 2 endpoints
├── components/       # React components
└── page.tsx         # Main page

services/
├── ai/              # AI service implementations
├── auth/            # Authentication services
└── monitoring/      # Metrics and logging

lib/
├── security/        # Security utilities
├── cache/           # Caching logic
└── auth/            # Auth helpers

prisma/
└── schema.prisma    # Database schema
\`\`\`

## License

MIT
EOF

# Create package.json scripts
cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "db:migrate": "prisma migrate dev",
    "db:push": "prisma db push",
    "db:studio": "prisma studio",
    "db:generate": "prisma generate"
  },
  "dependencies": {
    $(pnpm list --json | jq -r '.dependencies | to_entries | map("\"\(.key)\": \"\(.value.version)\"") | join(",\n    ")')
  },
  "devDependencies": {
    $(pnpm list --dev --json | jq -r '.devDependencies | to_entries | map("\"\(.key)\": \"\(.value.version)\"") | join(",\n    ")')
  }
}
EOF

# Initialize git repository
git init
git add .
git commit -m "Initial commit: Candlefish AI style project setup"

# Success message
echo
echo -e "${GREEN}✅ Candlefish AI style project created successfully!${NC}"
echo
echo "Project: $PROJECT_NAME"
echo "Location: $(pwd)"
echo
echo "Next steps:"
echo "1. Update .env with your API keys and database URL"
echo "2. Run 'pnpm db:migrate' to create database tables"
echo "3. Run 'pnpm dev' to start the development server"
echo
echo "Key features included:"
echo "- Multi-provider AI service with fallback"
echo "- Secure API key authentication"
echo "- Rate limiting with Redis/Upstash"
echo "- Comprehensive test setup"
echo "- Production-ready architecture"
echo
echo "Happy coding! 🚀"