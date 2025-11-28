#!/bin/bash
set -e

# Script to set up ClusterIssuer with your email

if [ -z "$1" ]; then
    echo "Usage: $0 <your-email@example.com>"
    echo ""
    echo "Example:"
    echo "  $0 admin@yourdomain.com"
    exit 1
fi

EMAIL=$1

echo "🔧 Setting up ClusterIssuers with email: $EMAIL"
echo ""

# Create temporary file with updated email
cat > /tmp/cluster-issuer-temp.yaml <<EOF
# ClusterIssuer for Let's Encrypt Production
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${EMAIL}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx

---
# ClusterIssuer for Let's Encrypt Staging (for testing)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${EMAIL}
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Apply the updated ClusterIssuers
kubectl apply -f /tmp/cluster-issuer-temp.yaml

# Clean up
rm /tmp/cluster-issuer-temp.yaml

echo ""
echo "✅ ClusterIssuers updated!"
echo ""
echo "Waiting for ClusterIssuers to be ready..."
sleep 5

# Check status
kubectl get clusterissuer

echo ""
echo "To verify, run:"
echo "  kubectl describe clusterissuer letsencrypt-prod"
echo "  kubectl describe clusterissuer letsencrypt-staging"

