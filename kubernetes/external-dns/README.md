# ExternalDNS

IAM policy for ExternalDNS to manage Route 53 DNS records.

## Overview

ExternalDNS automatically creates DNS records in Route 53 based on Kubernetes Ingress and Service annotations.

## IAM Policy

The `iam-policy.json` file defines the IAM permissions needed for ExternalDNS to manage Route 53 records.

## Installation

Install ExternalDNS via Helm with IRSA (IAM Roles for Service Accounts):

```bash
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

helm install external-dns external-dns/external-dns \
  --namespace external-dns \
  --create-namespace \
  --set provider=aws \
  --set domainFilters[0]=roodyadamsapp.com \
  --set policy=sync \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<IAM_ROLE_ARN> \
  --wait
```

## Usage

Add ExternalDNS annotation to Ingress:

```yaml
annotations:
  external-dns.alpha.kubernetes.io/hostname: eks.roodyadamsapp.com
```
