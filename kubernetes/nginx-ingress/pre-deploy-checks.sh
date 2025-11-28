#!/bin/bash
set -e

# Pre-deployment checks for NGINX Ingress Controller
# This script verifies all prerequisites before deployment

echo "🔍 Running pre-deployment checks..."
echo ""

ERRORS=0
WARNINGS=0

# Check 1: kubectl installation
echo "1️⃣  Checking kubectl installation..."
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || echo "unknown")
    echo "   ✅ kubectl is installed (version: $KUBECTL_VERSION)"
else
    echo "   ❌ kubectl is not installed"
    echo "      Install: https://kubernetes.io/docs/tasks/tools/"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: kubectl cluster connectivity
echo "2️⃣  Checking cluster connectivity..."
if kubectl cluster-info &> /dev/null; then
    CLUSTER_NAME=$(kubectl config current-context 2>/dev/null || echo "unknown")
    echo "   ✅ Successfully connected to cluster: $CLUSTER_NAME"
    
    # Check if we can get nodes
    if kubectl get nodes &> /dev/null; then
        NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
        echo "   ✅ Cluster has $NODE_COUNT node(s)"
        
        # Check node status
        NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready " | wc -l | tr -d ' ')
        if [ "$NOT_READY" -gt 0 ]; then
            echo "   ⚠️  Warning: Some nodes are not in Ready state"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo "   ⚠️  Warning: Cannot list nodes (may need additional permissions)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ❌ Cannot connect to Kubernetes cluster"
    echo "      Configure kubectl: aws eks update-kubeconfig --region <region> --name <cluster-name>"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 3: Helm installation
echo "3️⃣  Checking Helm installation..."
if command -v helm &> /dev/null; then
    HELM_VERSION=$(helm version --short 2>/dev/null | cut -d'+' -f1 || echo "unknown")
    echo "   ✅ Helm is installed (version: $HELM_VERSION)"
    
    # Check if helm repo is already added
    if helm repo list 2>/dev/null | grep -q "ingress-nginx"; then
        echo "   ✅ ingress-nginx Helm repository is already added"
    else
        echo "   ℹ️  ingress-nginx Helm repository will be added during deployment"
    fi
else
    echo "   ❌ Helm is not installed"
    echo "      Install: https://helm.sh/docs/intro/install/"
    echo "      Quick install (macOS): brew install helm"
    echo "      Quick install (Linux): curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 4: Check if namespace exists
echo "4️⃣  Checking namespace..."
NAMESPACE="ingress-nginx"
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "   ✅ Namespace '$NAMESPACE' already exists"
    
    # Check if ingress controller is already deployed
    if kubectl get deployment -n "$NAMESPACE" ingress-nginx-controller &> /dev/null; then
        echo "   ⚠️  Warning: NGINX Ingress Controller appears to be already deployed"
        echo "      Use 'helm upgrade' instead of 'helm install'"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ℹ️  Namespace '$NAMESPACE' will be created during deployment"
fi
echo ""

# Check 5: Check for required permissions
echo "5️⃣  Checking cluster permissions..."
if kubectl auth can-i create deployments --namespace="$NAMESPACE" &> /dev/null; then
    echo "   ✅ Has permission to create deployments"
else
    echo "   ⚠️  Warning: May not have permission to create deployments"
    WARNINGS=$((WARNINGS + 1))
fi

if kubectl auth can-i create services --namespace="$NAMESPACE" &> /dev/null; then
    echo "   ✅ Has permission to create services"
else
    echo "   ⚠️  Warning: May not have permission to create services"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 6: Check AWS credentials (if using AWS)
echo "6️⃣  Checking AWS configuration (for EKS)..."
if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
        AWS_REGION=$(aws configure get region 2>/dev/null || echo "not set")
        echo "   ✅ AWS credentials configured (Account: $AWS_ACCOUNT, Region: $AWS_REGION)"
    else
        echo "   ⚠️  Warning: AWS credentials not configured or invalid"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ℹ️  AWS CLI not installed (optional if cluster is already configured)"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Pre-deployment Check Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All checks passed! Ready to deploy."
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Checks passed with $WARNINGS warning(s). Deployment can proceed."
    echo ""
    exit 0
else
    echo "❌ Found $ERRORS error(s) and $WARNINGS warning(s)."
    echo ""
    echo "Please fix the errors before proceeding with deployment."
    echo ""
    exit 1
fi

