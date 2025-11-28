#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="external-dns"
SERVICE_ACCOUNT_NAME="external-dns"
DOMAIN="roodyadamsapp.com"
REGION="eu-west-2"

echo -e "${BLUE}🚀 Deploying ExternalDNS...${NC}"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}❌ Error: kubectl is not configured or cluster is not accessible${NC}"
  echo "Run: aws eks update-kubeconfig --region ${REGION} --name eks-cluster"
  exit 1
fi

# Check if role ARN file exists
if [ ! -f "external-dns-role-arn.txt" ]; then
  echo -e "${YELLOW}⚠️  IAM role not found. Creating it first...${NC}"
  ./create-iam-role.sh
fi

ROLE_ARN=$(cat external-dns-role-arn.txt)

if [ -z "$ROLE_ARN" ]; then
  echo -e "${RED}❌ Error: Could not read IAM role ARN${NC}"
  exit 1
fi

echo "📋 Configuration:"
echo "  Namespace: ${NAMESPACE}"
echo "  Service Account: ${SERVICE_ACCOUNT_NAME}"
echo "  Domain: ${DOMAIN}"
echo "  IAM Role ARN: ${ROLE_ARN}"
echo ""

# Create namespace
echo "📝 Creating namespace..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Create service account with IAM role annotation
echo "📝 Creating service account with IRSA..."
kubectl create serviceaccount ${SERVICE_ACCOUNT_NAME} \
  --namespace ${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

# Annotate service account with IAM role
kubectl annotate serviceaccount ${SERVICE_ACCOUNT_NAME} \
  --namespace ${NAMESPACE} \
  eks.amazonaws.com/role-arn=${ROLE_ARN} \
  --overwrite

# Deploy ExternalDNS using Helm
echo "📝 Installing ExternalDNS via Helm..."

# Add ExternalDNS Helm repo if not already added
if ! helm repo list | grep -q "external-dns"; then
  echo "📦 Adding ExternalDNS Helm repository..."
  helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
  helm repo update
fi

# Check if ExternalDNS is already installed
if helm list -n ${NAMESPACE} | grep -q "external-dns"; then
  echo -e "${YELLOW}⚠️  ExternalDNS is already installed. Upgrading...${NC}"
  helm upgrade external-dns external-dns/external-dns \
    --namespace ${NAMESPACE} \
    --set serviceAccount.create=false \
    --set serviceAccount.name=${SERVICE_ACCOUNT_NAME} \
    --set provider=aws \
    --set aws.region=${REGION} \
    --set domainFilters[0]=${DOMAIN} \
    --set txtOwnerId=${NAMESPACE} \
    --set policy=sync \
    --set logLevel=info \
    --set logFormat=text
else
  echo "📦 Installing ExternalDNS..."
  helm install external-dns external-dns/external-dns \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --set serviceAccount.create=false \
    --set serviceAccount.name=${SERVICE_ACCOUNT_NAME} \
    --set provider=aws \
    --set aws.region=${REGION} \
    --set domainFilters[0]=${DOMAIN} \
    --set txtOwnerId=${NAMESPACE} \
    --set policy=sync \
    --set logLevel=info \
    --set logFormat=text
fi

echo ""
echo -e "${GREEN}✅ ExternalDNS deployment initiated!${NC}"
echo ""
echo "⏳ Waiting for ExternalDNS pods to be ready..."
kubectl wait --for=condition=ready pod \
  --selector=app.kubernetes.io/name=external-dns \
  --namespace ${NAMESPACE} \
  --timeout=120s || echo "Pods may still be starting..."

echo ""
echo -e "${GREEN}✅ ExternalDNS is deployed!${NC}"
echo ""
echo "📋 Verification:"
echo "  Check pods: kubectl get pods -n ${NAMESPACE}"
echo "  Check logs: kubectl logs -n ${NAMESPACE} -l app.kubernetes.io/name=external-dns"
echo ""
echo "🌐 ExternalDNS will automatically manage DNS records for:"
echo "  • ${DOMAIN}"
echo "  • Any subdomain under ${DOMAIN} (e.g., eks.${DOMAIN})"
echo ""
echo "💡 To use ExternalDNS, add this annotation to your Ingress:"
echo "   external-dns.alpha.kubernetes.io/hostname: eks.${DOMAIN}"

