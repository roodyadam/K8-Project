#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="eks-cluster"
REGION="eu-west-2"
NAMESPACE="external-dns"
SERVICE_ACCOUNT_NAME="external-dns"
POLICY_NAME="${CLUSTER_NAME}-external-dns-policy"
ROLE_NAME="${CLUSTER_NAME}-external-dns-role"
DOMAIN="roodyadamsapp.com"

echo "🔧 Setting up IAM Role for ExternalDNS..."

# Get OIDC provider URL
OIDC_PROVIDER=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${REGION} --query 'cluster.identity.oidc.issuer' --output text | sed 's|https://||')
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$OIDC_PROVIDER" ]; then
  echo -e "${RED}❌ Error: Could not get OIDC provider. Make sure your cluster is accessible.${NC}"
  exit 1
fi

echo "📋 Cluster: ${CLUSTER_NAME}"
echo "📋 OIDC Provider: ${OIDC_PROVIDER}"
echo "📋 Account ID: ${ACCOUNT_ID}"
echo ""

# Check if OIDC provider exists in IAM
OIDC_EXISTS=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, '${OIDC_PROVIDER}')]" --output text)

if [ -z "$OIDC_EXISTS" ]; then
  echo -e "${YELLOW}⚠️  OIDC provider not found in IAM. Creating it...${NC}"
  aws iam create-open-id-connect-provider \
    --url "https://${OIDC_PROVIDER}" \
    --client-id-list "sts.amazonaws.com" \
    --thumbprint-list "9e99a48a9960b14926bb7f3b02e22da2b0ab7280" \
    --region ${REGION} || echo "OIDC provider may already exist"
fi

# Create IAM policy
echo "📝 Creating IAM policy..."
POLICY_ARN=$(aws iam create-policy \
  --policy-name ${POLICY_NAME} \
  --policy-document file://$(pwd)/iam-policy.json \
  --query 'Policy.Arn' \
  --output text 2>/dev/null || \
  aws iam get-policy --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}" --query 'Policy.Arn' --output text 2>/dev/null)

if [ -z "$POLICY_ARN" ]; then
  echo -e "${RED}❌ Error: Could not create or retrieve IAM policy${NC}"
  exit 1
fi

echo "✅ Policy ARN: ${POLICY_ARN}"

# Create trust policy for IRSA
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}",
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF
)

# Create IAM role
echo "📝 Creating IAM role..."
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

echo "✅ Role ARN: ${ROLE_ARN}"

# Attach policy to role
echo "📝 Attaching policy to role..."
aws iam attach-role-policy \
  --role-name ${ROLE_NAME} \
  --policy-arn ${POLICY_ARN} \
  --region ${REGION} 2>/dev/null || echo "Policy may already be attached"

echo ""
echo -e "${GREEN}✅ IAM Role setup complete!${NC}"
echo ""
echo "📋 Summary:"
echo "  Policy ARN: ${POLICY_ARN}"
echo "  Role ARN: ${ROLE_ARN}"
echo ""
echo "💾 Role ARN saved to: external-dns-role-arn.txt"
echo ${ROLE_ARN} > external-dns-role-arn.txt

echo ""
echo "Next steps:"
echo "  1. Run: ./deploy.sh"
echo "  2. ExternalDNS will automatically manage DNS records for: ${DOMAIN}"

