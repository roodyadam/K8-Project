# NGINX Ingress Controller Deployment

This directory contains the configuration and deployment scripts for the NGINX Ingress Controller on your EKS cluster.

## Overview

The NGINX Ingress Controller is deployed to handle incoming HTTP/HTTPS traffic and route it to the appropriate Kubernetes services. It's configured to work with CertManager for automatic TLS certificate management.

## Prerequisites

1. **kubectl** configured to connect to your EKS cluster
2. **Helm 3.x** installed
3. EKS cluster is running and accessible
4. CertManager installed (for TLS certificate management)

## Quick Start

### 1. Deploy NGINX Ingress Controller

```bash
# Make the deployment script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

Or manually with Helm:

```bash
# Add the Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Create namespace
kubectl create namespace ingress-nginx

# Deploy using Helm
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --values helm-values.yaml \
  --wait
```

### 2. Verify Deployment

```bash
# Check pods
kubectl get pods -n ingress-nginx

# Check service (get LoadBalancer address)
kubectl get service -n ingress-nginx ingress-nginx-controller

# Check ingress class
kubectl get ingressclass
```

### 3. Get LoadBalancer Address

```bash
# Get the external IP/hostname
kubectl get service -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Configuration

### Helm Values

The `helm-values.yaml` file contains the configuration for the NGINX Ingress Controller:

- **Service Type**: LoadBalancer (creates AWS NLB)
- **Replicas**: 2 (for high availability)
- **Metrics**: Enabled for Prometheus monitoring
- **SSL Passthrough**: Enabled
- **Default Ingress Class**: Set to `nginx`

### Customizing Configuration

Edit `helm-values.yaml` to customize:

- Resource limits and requests
- SSL/TLS settings
- Logging configuration
- Annotations for AWS Load Balancer

## Using the Ingress Controller

### Basic Ingress Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80
```

### HTTPS/TLS with CertManager

See `ingress-example.yaml` for a complete example with TLS configuration.

Key annotations:
- `cert-manager.io/cluster-issuer: "letsencrypt-prod"` - Automatically provisions TLS certificate
- `nginx.ingress.kubernetes.io/ssl-redirect: "true"` - Redirects HTTP to HTTPS

## Integration with CertManager

The NGINX Ingress Controller is pre-configured to work with CertManager:

1. CertManager watches for Ingress resources with the `cert-manager.io/cluster-issuer` annotation
2. It automatically creates a Certificate resource
3. The certificate is provisioned via Let's Encrypt (or your configured issuer)
4. CertManager creates a Kubernetes secret with the TLS certificate
5. NGINX Ingress Controller uses this secret for TLS termination

## Monitoring

Metrics are enabled and exposed on port 10254. To scrape with Prometheus:

```yaml
# Prometheus ServiceMonitor example
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/component: controller
  endpoints:
    - port: http
      path: /metrics
```

## Troubleshooting

### Check Controller Logs

```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Check Service Status

```bash
kubectl describe service -n ingress-nginx ingress-nginx-controller
```

### Test Ingress Configuration

```bash
# Check ingress resources
kubectl get ingress --all-namespaces

# Describe specific ingress
kubectl describe ingress <ingress-name> -n <namespace>
```

### Common Issues

1. **LoadBalancer not getting an address**: 
   - Check AWS IAM permissions for the node group
   - Verify security groups allow traffic
   - Check AWS console for Load Balancer creation

2. **502 Bad Gateway**:
   - Verify backend service is running
   - Check service endpoints: `kubectl get endpoints`
   - Verify service selector matches pod labels

3. **TLS certificate issues**:
   - Ensure CertManager is installed and running
   - Check Certificate resources: `kubectl get certificates`
   - Verify ClusterIssuer is configured correctly

## Upgrading

```bash
helm repo update
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --values helm-values.yaml
```

## Uninstalling

```bash
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```

## Additional Resources

- [NGINX Ingress Controller Documentation](https://kubernetes.github.io/ingress-nginx/)
- [NGINX Ingress Controller GitHub](https://github.com/kubernetes/ingress-nginx)
- [Helm Chart Documentation](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx)

