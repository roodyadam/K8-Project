# NGINX Ingress Controller

Helm values configuration for NGINX Ingress Controller on EKS.

## Installation

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values helm-values.yaml \
  --wait
```

## Configuration

The `helm-values.yaml` file configures:
- LoadBalancer service type (Classic Load Balancer)
- 2 replicas for high availability
- Metrics enabled for Prometheus
- Default ingress class: `nginx`

## Verification

```bash
kubectl get pods -n ingress-nginx
kubectl get service -n ingress-nginx ingress-nginx-controller
kubectl get ingressclass
```
