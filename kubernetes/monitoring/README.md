# Monitoring and Observability

Prometheus and Grafana setup for Kubernetes cluster monitoring.

## Architecture

- **Prometheus**: Metrics collection from pods, nodes, namespaces, services, and NGINX Ingress
- **Grafana**: Visualization and dashboards
- **ServiceMonitor**: Automatic service discovery for Prometheus

## Components

### Prometheus
- Installed via Helm (kube-prometheus-stack)
- 30-day metrics retention
- 50GB persistent storage
- Scrapes Kubernetes API, nodes, pods, services
- ServiceMonitor for NGINX Ingress metrics

### Grafana
- Installed via Helm
- Pre-configured Prometheus data source
- Custom dashboards:
  - Cluster Overview (CPU/Memory usage)
  - Pod Health Dashboard
  - Node Status Dashboard
  - Ingress Traffic Dashboard
- 10GB persistent storage for dashboards
- Accessible at: https://grafana.roodyadamsapp.com

## Installation

Managed automatically via Terraform:

```bash
terraform apply
```

This installs:
1. Prometheus (kube-prometheus-stack)
2. Grafana with dashboards
3. ServiceMonitor for NGINX Ingress
4. Grafana Ingress with TLS

## Access

### Grafana UI
- URL: https://grafana.roodyadamsapp.com
- Username: `admin`
- Password: `admin` (change after first login)

### Prometheus UI
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Then access: http://localhost:9090

## Dashboards

### Cluster Overview
- Cluster CPU usage by namespace
- Cluster memory usage by namespace
- Top 10 high CPU usage pods
- Top 10 high memory usage pods

### Pod Health
- Pod status (Running, Pending, Failed, Succeeded)
- Pod restart rates
- Pod CPU usage
- Pod memory usage
- Unhealthy pods table

### Node Status
- Node readiness status
- Node CPU usage percentage
- Node memory usage percentage
- Node disk usage percentage
- Node resource allocation table

### Ingress Traffic
- Ingress requests rate
- Request duration (p95, p99)
- HTTP status codes (2xx, 3xx, 4xx, 5xx)
- Ingress traffic (bytes sent/received)
- Active connections

## Metrics Collected

- **Kubernetes API**: Pods, nodes, namespaces, services
- **Node Exporter**: CPU, memory, disk, network
- **Kube State Metrics**: Cluster state metrics
- **NGINX Ingress**: Request rates, latency, status codes

## Configuration

### Prometheus
- Retention: 30 days
- Storage: 50GB PVC
- Scrape interval: 30s (default)

### Grafana
- Storage: 10GB PVC
- Default dashboards: Pre-loaded
- Custom dashboards: Auto-discovered from ConfigMaps

## Troubleshooting

### Check Prometheus
```bash
kubectl get pods -n monitoring
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
```

### Check Grafana
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

### Verify ServiceMonitor
```bash
kubectl get servicemonitor -A
kubectl describe servicemonitor nginx-ingress -n ingress-nginx
```

### Check Metrics Endpoint
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller-metrics
curl http://<service-ip>:10254/metrics
```


