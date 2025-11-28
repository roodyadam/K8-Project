#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGION="eu-west-2"
ROLE_NAME="github-actions-terraform-role"
POLICY_NAME="github-actions-terraform-policy"
GITHUB_ORG="${1}"
GITHUB_REPO="${2}"

if [ -z "$GITHUB_ORG" ] || [ -z "$GITHUB_REPO" ]; then
  echo -e "${RED}❌ Error: GitHub organization and repository name required${NC}"
  echo ""
  echo "Usage: ./setup-github-oidc.sh <github-org> <github-repo>"
  echo "Example: ./setup-github-oidc.sh myorg my-repo"
  exit 1
fi

echo -e "${BLUE}🔧 Setting up GitHub Actions OIDC and IAM Role...${NC}"
echo ""

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$ACCOUNT_ID" ]; then
  echo -e "${RED}❌ Error: Could not get AWS account ID. Check your AWS credentials.${NC}"
  exit 1
fi

echo "📋 Configuration:"
echo "  AWS Account ID: ${ACCOUNT_ID}"
echo "  Region: ${REGION}"
echo "  GitHub Org: ${GITHUB_ORG}"
echo "  GitHub Repo: ${GITHUB_REPO}"
echo "  IAM Role Name: ${ROLE_NAME}"
echo "  IAM Policy Name: ${POLICY_NAME}"
echo ""

# GitHub OIDC Provider URL
OIDC_PROVIDER_URL="https://token.actions.githubusercontent.com"
OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

# Check if OIDC provider exists
echo "🔍 Checking for GitHub OIDC provider..."
OIDC_EXISTS=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')]" --output text 2>/dev/null || echo "")

if [ -z "$OIDC_EXISTS" ]; then
  echo -e "${YELLOW}📝 Creating GitHub OIDC provider...${NC}"
  
  # Get GitHub's thumbprint (this is a well-known value)
  THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"
  
  aws iam create-open-id-connect-provider \
    --url "${OIDC_PROVIDER_URL}" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "${THUMBPRINT}" \
    --region ${REGION} 2>/dev/null || {
    echo -e "${RED}❌ Error: Failed to create OIDC provider${NC}"
    exit 1
  }
  
  echo -e "${GREEN}✅ OIDC provider created${NC}"
else
  echo -e "${GREEN}✅ OIDC provider already exists${NC}"
fi

# Create IAM policy for Terraform operations
echo ""
echo "📝 Creating IAM policy for Terraform operations..."

POLICY_DOCUMENT=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "iam:*",
        "kms:*",
        "logs:*",
        "route53:*",
        "s3:*",
        "dynamodb:*",
        "autoscaling:*",
        "elasticloadbalancing:*",
        "sts:GetCallerIdentity",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF
)

# Create or get policy
POLICY_ARN=$(aws iam create-policy \
  --policy-name ${POLICY_NAME} \
  --policy-document "${POLICY_DOCUMENT}" \
  --query 'Policy.Arn' \
  --output text 2>/dev/null || \
  aws iam get-policy --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}" --query 'Policy.Arn' --output text 2>/dev/null)

if [ -z "$POLICY_ARN" ]; then
  echo -e "${RED}❌ Error: Could not create or retrieve IAM policy${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Policy ARN: ${POLICY_ARN}${NC}"

# Create trust policy for GitHub Actions
echo ""
echo "📝 Creating IAM role with OIDC trust policy..."

TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_PROVIDER_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF
)

# Create IAM role
ROLE_ARN=$(aws iam create-role \
  --role-name ${ROLE_NAME} \
  --assume-role-policy-document "${TRUST_POLICY}" \
  --query 'Role.Arn' \
  --output text 2>/dev/null || \
  aws iam get-role --role-name ${ROLE_NAME} --query 'Role.Arn' --output text 2>/dev/null)

if [ -z "$ROLE_ARN" ]; then
  echo -e "${RED}❌ Error: Could not create or retrieve IAM role${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Role ARN: ${ROLE_ARN}${NC}"

# Attach policy to role
echo ""
echo "📝 Attaching policy to role..."
aws iam attach-role-policy \
  --role-name ${ROLE_NAME} \
  --policy-arn ${POLICY_ARN} \
  --region ${REGION} 2>/dev/null || echo "Policy may already be attached"

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1. Add GitHub Secrets:"
echo ""
echo "   Go to: https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/settings/secrets/actions"
echo ""
echo "   Add these secrets:"
echo ""
echo "   ${GREEN}AWS_ROLE_ARN${NC}"
echo "   Value: ${ROLE_ARN}"
echo ""
echo "   ${GREEN}TF_STATE_BUCKET${NC}"
echo "   Value: <your-s3-bucket-name> (run ./setup-backend.sh first)"
echo ""
echo "   ${GREEN}TF_STATE_LOCK_TABLE${NC}"
echo "   Value: <your-dynamodb-table-name> (run ./setup-backend.sh first)"
echo ""
echo "2. Set up S3 and DynamoDB backend:"
echo ""
echo "   ${YELLOW}cd terraform${NC}"
echo "   ${YELLOW}./setup-backend.sh <bucket-name> <table-name>${NC}"
echo ""
echo "3. Test the workflow:"
echo ""
echo "   Push changes to trigger the workflow, or manually trigger it"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "💾 Role ARN saved to: github-actions-role-arn.txt"
echo ${ROLE_ARN} > github-actions-role-arn.txt

