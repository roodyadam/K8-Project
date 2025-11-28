#!/bin/bash
set -e

# Script to install CertManager for TLS certificate management

NAMESPACE="cert-manager"
RELEASE_NAME="cert-manager"
CHART_REPO="https://charts.jetstack.io"
CHART_NAME="jetstack/cert-manager"

echo "🚀 Installing CertManager..."
echo ""

# Check prerequisites
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed"
    exit 1
fi

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repository
echo "📥 Adding CertManager Helm repository..."
helm repo add jetstack ${CHART_REPO}
helm repo update

# Install CertManager CRDs first
echo "🔧 Installing CertManager CRDs..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.crds.yaml

# Wait for CRDs to be ready
echo "⏳ Waiting for CRDs to be ready..."
sleep 5

# Install CertManager
echo "🔧 Installing CertManager..."
helm upgrade --install ${RELEASE_NAME} ${CHART_NAME} \
  --namespace ${NAMESPACE} \
  --version v1.14.5 \
  --set installCRDs=false \
  --set global.leaderElection.namespace=${NAMESPACE} \
  --wait \
  --timeout 5m

# Wait for pods to be ready
echo "⏳ Waiting for CertManager pods to be ready..."
kubectl wait --namespace ${NAMESPACE} \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=300s

echo ""
echo "✅ CertManager installed successfully!"
echo ""
echo "To verify, run:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo "  kubectl get crd | grep cert-manager"

