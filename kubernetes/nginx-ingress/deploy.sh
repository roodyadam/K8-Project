#!/bin/bash
set -e

# Script to deploy NGINX Ingress Controller using Helm

NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
CHART_REPO="https://kubernetes.github.io/ingress-nginx"
CHART_NAME="ingress-nginx/ingress-nginx"

echo "🚀 Deploying NGINX Ingress Controller..."
echo ""

# Run pre-deployment checks
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/pre-deploy-checks.sh" ]; then
    echo "Running pre-deployment checks..."
    if ! bash "$SCRIPT_DIR/pre-deploy-checks.sh"; then
        echo ""
        echo "❌ Pre-deployment checks failed. Please fix the issues above."
        exit 1
    fi
    echo ""
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please configure kubectl."
    echo ""
    echo "For EKS clusters, run:"
    echo "  aws eks update-kubeconfig --region <region> --name <cluster-name>"
    exit 1
fi

# Create namespace if it doesn't exist
echo "📦 Creating namespace..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repository
echo "📥 Adding NGINX Ingress Helm repository..."
helm repo add ingress-nginx ${CHART_REPO}
helm repo update

# Deploy NGINX Ingress Controller
echo "🔧 Deploying NGINX Ingress Controller..."
helm upgrade --install ${RELEASE_NAME} ${CHART_NAME} \
  --namespace ${NAMESPACE} \
  --values helm-values.yaml \
  --wait \
  --timeout 5m

# Wait for deployment to be ready
echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ${NAMESPACE} \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Get the LoadBalancer address
echo "📋 Getting LoadBalancer address..."
kubectl get service -n ${NAMESPACE} ${RELEASE_NAME}-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo "LoadBalancer address not yet available"

echo ""
echo "✅ NGINX Ingress Controller deployed successfully!"
echo ""
echo "To get the LoadBalancer address, run:"
echo "  kubectl get service -n ${NAMESPACE} ${RELEASE_NAME}-controller"
echo ""
echo "To check the status, run:"
echo "  kubectl get pods -n ${NAMESPACE}"

