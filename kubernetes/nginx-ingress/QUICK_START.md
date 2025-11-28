# NGINX Ingress Controller - Quick Start Guide

## Prerequisites Check

Before deploying, ensure you have:

```bash
# 1. kubectl configured
kubectl cluster-info

# 2. Helm installed
helm version

# 3. Cluster access verified
kubectl get nodes
```

## Deployment Steps

### Option 1: Using the Deployment Script (Recommended)

```bash
cd kubernetes/nginx-ingress
./deploy.sh
```

### Option 2: Manual Helm Deployment

```bash
# Add Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Create namespace
kubectl create namespace ingress-nginx

# Deploy
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --values helm-values.yaml \
  --wait
```

## Verify Deployment

```bash
# Check pods are running
kubectl get pods -n ingress-nginx

# Get LoadBalancer address
kubectl get service -n ingress-nginx ingress-nginx-controller

# Check ingress class
kubectl get ingressclass nginx
```

## Get the LoadBalancer Address

```bash
# Get the external hostname/IP
EXTERNAL_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "NGINX Ingress Controller is available at: $EXTERNAL_IP"
```

## Create Your First Ingress

1. **Deploy a test application** (optional):

```bash
kubectl create deployment nginx-test --image=nginx
kubectl expose deployment nginx-test --port=80 --type=ClusterIP
```

2. **Create an Ingress resource**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: test.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-test
                port:
                  number: 80
```

Apply it:
```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: test.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-test
                port:
                  number: 80
EOF
```

3. **Test the ingress** (update with your LoadBalancer address):

```bash
# Add to /etc/hosts or use curl with Host header
curl -H "Host: test.example.com" http://<LOADBALANCER-ADDRESS>
```

## HTTPS/TLS Setup (After CertManager is Installed)

Once CertManager is installed, you can create HTTPS ingresses:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - eks.example.com
      secretName: example-tls-secret
  rules:
    - host: eks.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

## Troubleshooting

### Controller not starting?
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### LoadBalancer not getting an address?
- Check AWS IAM permissions
- Verify security groups
- Check AWS console for Load Balancer

### 502 Bad Gateway?
- Check backend service: `kubectl get endpoints`
- Verify service selector matches pod labels
- Check service is running: `kubectl get pods`

## Next Steps

1. Install CertManager for TLS certificate management
2. Configure DNS to point to the LoadBalancer address
3. Create Ingress resources for your applications
4. Set up monitoring (Prometheus/Grafana)

