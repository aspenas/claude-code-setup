#!/bin/bash
# Complete AWS Setup for Jonathon's Development Environment
# Author: Patrick Smith (patrick@candlefish.ai)
# This script automates the entire AWS account setup process
# Documentation: https://docs.candlefish.ai/aws-setup

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="jonathon-dev"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        error "AWS CLI not found. Please install it first: brew install awscli"
    fi
    
    if ! command -v jq &> /dev/null; then
        error "jq not found. Please install it first: brew install jq"
    fi
}

# Configure AWS CLI
configure_aws_cli() {
    log "Configuring AWS CLI..."
    
    echo "Please have your AWS credentials ready."
    echo "You can find them in the AWS Console under 'Security Credentials'"
    echo
    
    read -p "Enter AWS Access Key ID: " aws_access_key
    read -s -p "Enter AWS Secret Access Key: " aws_secret_key
    echo
    read -p "Enter preferred AWS Region (default: us-east-1): " region
    region="${region:-us-east-1}"
    
    # Configure default profile
    aws configure set aws_access_key_id "$aws_access_key"
    aws configure set aws_secret_access_key "$aws_secret_key"
    aws configure set region "$region"
    aws configure set output json
    
    # Test configuration
    if aws sts get-caller-identity &> /dev/null; then
        log "AWS CLI configured successfully!"
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        info "Account ID: $ACCOUNT_ID"
    else
        error "Failed to configure AWS CLI. Please check your credentials."
    fi
}

# Create IAM user for daily use
create_iam_user() {
    log "Creating IAM user for daily operations..."
    
    local username="${PROJECT_NAME}"
    
    # Create user
    if aws iam create-user --user-name "$username" 2>/dev/null; then
        log "Created IAM user: $username"
    else
        warning "User $username already exists"
    fi
    
    # Attach policies
    local policies=(
        "arn:aws:iam::aws:policy/PowerUserAccess"
        "arn:aws:iam::aws:policy/IAMFullAccess"
    )
    
    for policy in "${policies[@]}"; do
        aws iam attach-user-policy --user-name "$username" --policy-arn "$policy"
    done
    
    # Create access key
    local key_output=$(aws iam create-access-key --user-name "$username")
    local access_key=$(echo "$key_output" | jq -r '.AccessKey.AccessKeyId')
    local secret_key=$(echo "$key_output" | jq -r '.AccessKey.SecretAccessKey')
    
    # Save credentials securely
    cat > ~/.aws/credentials-${PROJECT_NAME} << EOF
[${PROJECT_NAME}]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
EOF
    
    chmod 600 ~/.aws/credentials-${PROJECT_NAME}
    
    info "IAM user created. Credentials saved to ~/.aws/credentials-${PROJECT_NAME}"
    info "Add to ~/.aws/credentials to use with: aws --profile ${PROJECT_NAME}"
}

# Create S3 buckets
create_s3_buckets() {
    log "Creating S3 buckets..."
    
    local buckets=(
        "${PROJECT_NAME}-uploads-${TIMESTAMP}"
        "${PROJECT_NAME}-backups-${TIMESTAMP}"
        "${PROJECT_NAME}-static-${TIMESTAMP}"
    )
    
    for bucket in "${buckets[@]}"; do
        if aws s3 mb "s3://$bucket" --region "$AWS_REGION"; then
            log "Created bucket: $bucket"
            
            # Enable versioning on backups bucket
            if [[ "$bucket" == *"backups"* ]]; then
                aws s3api put-bucket-versioning \
                    --bucket "$bucket" \
                    --versioning-configuration Status=Enabled
            fi
            
            # Set up static website hosting for static bucket
            if [[ "$bucket" == *"static"* ]]; then
                aws s3 website "s3://$bucket" \
                    --index-document index.html \
                    --error-document error.html
            fi
        fi
    done
    
    # Save bucket names
    cat > ~/.aws/${PROJECT_NAME}-buckets.json << EOF
{
    "uploads": "${PROJECT_NAME}-uploads-${TIMESTAMP}",
    "backups": "${PROJECT_NAME}-backups-${TIMESTAMP}",
    "static": "${PROJECT_NAME}-static-${TIMESTAMP}"
}
EOF
}

# Set up Secrets Manager
setup_secrets_manager() {
    log "Setting up AWS Secrets Manager..."
    
    # Create secret for API keys
    local secret_name="${PROJECT_NAME}/api-keys"
    
    cat > /tmp/api-keys.json << EOF
{
    "ANTHROPIC_API_KEY": "sk-ant-...",
    "OPENAI_API_KEY": "sk-...",
    "GITHUB_TOKEN": "ghp_...",
    "DATABASE_URL": "postgresql://user:pass@host:5432/db"
}
EOF
    
    if aws secretsmanager create-secret \
        --name "$secret_name" \
        --description "API keys for $PROJECT_NAME" \
        --secret-string file:///tmp/api-keys.json \
        --region "$AWS_REGION" 2>/dev/null; then
        log "Created secret: $secret_name"
    else
        warning "Secret $secret_name already exists. Updating..."
        aws secretsmanager update-secret \
            --secret-id "$secret_name" \
            --secret-string file:///tmp/api-keys.json \
            --region "$AWS_REGION"
    fi
    
    rm /tmp/api-keys.json
    
    info "Remember to update the secret with your actual API keys!"
}

# Create DynamoDB tables
create_dynamodb_tables() {
    log "Creating DynamoDB tables..."
    
    # Sessions table
    aws dynamodb create-table \
        --table-name "${PROJECT_NAME}-sessions" \
        --attribute-definitions \
            AttributeName=id,AttributeType=S \
        --key-schema \
            AttributeName=id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" 2>/dev/null || warning "Sessions table already exists"
    
    # Cache table
    aws dynamodb create-table \
        --table-name "${PROJECT_NAME}-cache" \
        --attribute-definitions \
            AttributeName=key,AttributeType=S \
        --key-schema \
            AttributeName=key,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" 2>/dev/null || warning "Cache table already exists"
}

# Set up CloudFormation stack
setup_cloudformation() {
    log "Creating CloudFormation template..."
    
    cat > ~/.aws/${PROJECT_NAME}-stack.yaml << 'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Jonathon Development Infrastructure Stack'

Parameters:
  ProjectName:
    Type: String
    Default: jonathon-dev
    Description: Project name for resource naming

Resources:
  # Lambda execution role
  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub '${ProjectName}-lambda-role'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: 'sts:AssumeRole'
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyName: SecretAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 'secretsmanager:GetSecretValue'
                Resource: !Sub 'arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:${ProjectName}/*'

  # API Gateway
  ApiGateway:
    Type: AWS::ApiGatewayV2::Api
    Properties:
      Name: !Sub '${ProjectName}-api'
      ProtocolType: HTTP
      CorsConfiguration:
        AllowOrigins:
          - '*'
        AllowMethods:
          - GET
          - POST
          - PUT
          - DELETE
        AllowHeaders:
          - '*'

  # CloudWatch Log Group
  LogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub '/aws/lambda/${ProjectName}'
      RetentionInDays: 14

Outputs:
  ApiEndpoint:
    Description: API Gateway endpoint URL
    Value: !GetAtt ApiGateway.ApiEndpoint
    Export:
      Name: !Sub '${ProjectName}-api-endpoint'
  
  LambdaRoleArn:
    Description: Lambda execution role ARN
    Value: !GetAtt LambdaExecutionRole.Arn
    Export:
      Name: !Sub '${ProjectName}-lambda-role-arn'
EOF
    
    # Deploy stack
    log "Deploying CloudFormation stack..."
    aws cloudformation create-stack \
        --stack-name "${PROJECT_NAME}-infrastructure" \
        --template-body file://${HOME}/.aws/${PROJECT_NAME}-stack.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameters ParameterKey=ProjectName,ParameterValue=${PROJECT_NAME} \
        --region "$AWS_REGION" 2>/dev/null || warning "Stack already exists"
}

# Create helper scripts
create_helper_scripts() {
    log "Creating helper scripts..."
    
    mkdir -p ~/.aws/scripts
    
    # Script to load API keys from Secrets Manager
    cat > ~/.aws/scripts/load-${PROJECT_NAME}-secrets.sh << 'EOF'
#!/bin/bash
# Load secrets from AWS Secrets Manager

SECRET_NAME="jonathon-dev/api-keys"
REGION="${AWS_REGION:-us-east-1}"

# Get secret value
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text)

# Export as environment variables
export ANTHROPIC_API_KEY=$(echo "$SECRET_JSON" | jq -r .ANTHROPIC_API_KEY)
export OPENAI_API_KEY=$(echo "$SECRET_JSON" | jq -r .OPENAI_API_KEY)
export GITHUB_TOKEN=$(echo "$SECRET_JSON" | jq -r .GITHUB_TOKEN)
export DATABASE_URL=$(echo "$SECRET_JSON" | jq -r .DATABASE_URL)

echo "Secrets loaded successfully!"
EOF
    
    # Script to update secrets
    cat > ~/.aws/scripts/update-${PROJECT_NAME}-secrets.sh << 'EOF'
#!/bin/bash
# Update secrets in AWS Secrets Manager

SECRET_NAME="jonathon-dev/api-keys"
REGION="${AWS_REGION:-us-east-1}"

echo "Updating secrets in AWS Secrets Manager..."
echo "Leave blank to keep existing value"

# Get current secrets
CURRENT=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text)

# Get new values
read -s -p "Anthropic API Key: " anthropic_key
echo
read -s -p "OpenAI API Key: " openai_key
echo
read -s -p "GitHub Token: " github_token
echo
read -p "Database URL: " database_url

# Use existing values if not provided
anthropic_key="${anthropic_key:-$(echo "$CURRENT" | jq -r .ANTHROPIC_API_KEY)}"
openai_key="${openai_key:-$(echo "$CURRENT" | jq -r .OPENAI_API_KEY)}"
github_token="${github_token:-$(echo "$CURRENT" | jq -r .GITHUB_TOKEN)}"
database_url="${database_url:-$(echo "$CURRENT" | jq -r .DATABASE_URL)}"

# Update secret
aws secretsmanager update-secret \
    --secret-id "$SECRET_NAME" \
    --secret-string "{
        \"ANTHROPIC_API_KEY\": \"$anthropic_key\",
        \"OPENAI_API_KEY\": \"$openai_key\",
        \"GITHUB_TOKEN\": \"$github_token\",
        \"DATABASE_URL\": \"$database_url\"
    }" \
    --region "$REGION"

echo "Secrets updated successfully!"
EOF
    
    chmod +x ~/.aws/scripts/*.sh
}

# Print summary
print_summary() {
    echo
    echo -e "${GREEN}AWS Setup Complete!${NC}"
    echo -e "${GREEN}==================${NC}"
    echo
    echo "Resources created:"
    echo "- IAM User: ${PROJECT_NAME}-dev"
    echo "- S3 Buckets: Check ~/.aws/${PROJECT_NAME}-buckets.json"
    echo "- Secrets Manager: ${PROJECT_NAME}/api-keys"
    echo "- DynamoDB Tables: ${PROJECT_NAME}-sessions, ${PROJECT_NAME}-cache"
    echo "- CloudFormation Stack: ${PROJECT_NAME}-infrastructure"
    echo
    echo "Helper scripts:"
    echo "- Load secrets: ~/.aws/scripts/load-${PROJECT_NAME}-secrets.sh"
    echo "- Update secrets: ~/.aws/scripts/update-${PROJECT_NAME}-secrets.sh"
    echo
    echo "Next steps:"
    echo "1. Update API keys: ~/.aws/scripts/update-${PROJECT_NAME}-secrets.sh"
    echo "2. Add AWS profile to ~/.aws/credentials from ~/.aws/credentials-${PROJECT_NAME}"
    echo "3. Use profile: export AWS_PROFILE=${PROJECT_NAME}"
    echo
    echo "To use in your projects:"
    echo "  source ~/.aws/scripts/load-${PROJECT_NAME}-secrets.sh"
    echo
}

# Main execution
main() {
    check_prerequisites
    
    echo -e "${BLUE}AWS Account Setup for Jonathon${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo
    
    # Check if AWS is already configured
    if aws sts get-caller-identity &> /dev/null; then
        info "AWS CLI already configured"
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        info "Using account: $ACCOUNT_ID"
    else
        configure_aws_cli
    fi
    
    # Run setup steps
    create_iam_user
    create_s3_buckets
    setup_secrets_manager
    create_dynamodb_tables
    setup_cloudformation
    create_helper_scripts
    
    print_summary
}

# Run main function
main "$@"