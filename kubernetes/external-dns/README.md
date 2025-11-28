# ExternalDNS Setup for EKS

This directory contains the configuration and deployment scripts for ExternalDNS, which automatically manages DNS records in Route 53 based on Kubernetes Ingress and Service resources.

## Overview

ExternalDNS will:
- Watch for Ingress and Service resources with DNS annotations
- Automatically create/update DNS records in Route 53
- Point your domain (`eks.roodyadamsapp.com`) to your LoadBalancer
- Clean up DNS records when resources are deleted

## Prerequisites

1. **Route 53 Hosted Zone**: You need a Route 53 hosted zone for `roodyadamsapp.com`
   - If you don't have one, create it in the AWS Console or via AWS CLI:
     ```bash
     aws route53 create-hosted-zone --name roodyadamsapp.com --caller-reference $(date +%s)
     ```

2. **kubectl configured**: Make sure kubectl is configured for your EKS cluster
   ```bash
   aws eks update-kubeconfig --region eu-west-2 --name eks-cluster
   ```

3. **Helm installed**: ExternalDNS is deployed via Helm
   ```bash
   # Install Helm if not already installed
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

## Deployment Steps

### Step 1: Create IAM Role (IRSA)

ExternalDNS needs IAM permissions to manage Route 53 records. This is done using IAM Roles for Service Accounts (IRSA).

```bash
cd kubernetes/external-dns
./create-iam-role.sh
```

This script will:
- Create an IAM policy for Route 53 access
- Create an IAM role with IRSA trust policy
- Attach the policy to the role
- Save the role ARN for deployment

### Step 2: Deploy ExternalDNS

```bash
./deploy.sh
```

This script will:
- Create the `external-dns` namespace
- Create a service account with IAM role annotation
- Install ExternalDNS via Helm
- Configure it to manage DNS records for `roodyadamsapp.com`

### Step 3: Verify Deployment

```bash
# Check ExternalDNS pods
kubectl get pods -n external-dns

# Check ExternalDNS logs
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns

# Check service account annotation
kubectl get serviceaccount external-dns -n external-dns -o yaml
```

## Usage

### Creating DNS Records Automatically

To automatically create DNS records, add the ExternalDNS annotation to your Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    # ExternalDNS annotation
    external-dns.alpha.kubernetes.io/hostname: eks.roodyadamsapp.com
    # CertManager annotation (optional, for TLS)
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - eks.roodyadamsapp.com
      secretName: my-app-tls
  rules:
    - host: eks.roodyadamsapp.com
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

### What Happens Automatically

1. **ExternalDNS** detects the annotation and creates an A record in Route 53:
   - `eks.roodyadamsapp.com` → LoadBalancer IP address

2. **CertManager** (if configured) provisions a TLS certificate:
   - Creates a Certificate resource
   - Validates domain ownership via HTTP-01 challenge
   - Stores certificate in the specified secret

3. **NGINX Ingress** uses the certificate for HTTPS termination

## Configuration

### Domain Filter

ExternalDNS is configured to only manage DNS records for `roodyadamsapp.com` and its subdomains. This is set in the Helm values:

```yaml
domainFilters[0]=roodyadamsapp.com
```

### Policy

ExternalDNS is set to `sync` policy, which means:
- It will create DNS records for annotated resources
- It will update DNS records when LoadBalancer addresses change
- It will delete DNS records when resources are removed

## Troubleshooting

### ExternalDNS not creating DNS records

1. **Check IAM permissions**:
   ```bash
   kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns
   ```
   Look for permission errors.

2. **Verify Route 53 hosted zone exists**:
   ```bash
   aws route53 list-hosted-zones --query "HostedZones[?Name=='roodyadamsapp.com.']"
   ```

3. **Check service account annotation**:
   ```bash
   kubectl get serviceaccount external-dns -n external-dns -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
   ```

### DNS record created but not resolving

1. **Check DNS propagation** (can take a few minutes):
   ```bash
   dig eks.roodyadamsapp.com
   nslookup eks.roodyadamsapp.com
   ```

2. **Verify nameservers** are pointing to Route 53:
   ```bash
   aws route53 get-hosted-zone --id <hosted-zone-id> --query 'HostedZone.NameServers'
   ```

## Files

- `iam-policy.json` - IAM policy for Route 53 access
- `create-iam-role.sh` - Script to create IAM role with IRSA
- `deploy.sh` - Script to deploy ExternalDNS
- `ingress-example.yaml` - Example Ingress with ExternalDNS annotation
- `README.md` - This file

## Additional Resources

- [ExternalDNS Documentation](https://github.com/kubernetes-sigs/external-dns)
- [AWS IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Route 53 Documentation](https://docs.aws.amazon.com/route53/)

