# Aim Application - Helm Chart

Helm chart for deploying the Aim ML experiment tracking application to EKS.

## Chart Structure

```
kubernetes/apps/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
└── templates/
    ├── _helpers.tpl        # Template helpers
    ├── deployment.yaml     # Deployment template
    ├── service.yaml        # Service template
    ├── ingress.yaml        # Ingress template
    └── pvc.yaml            # PersistentVolumeClaim template
```

## Installation

### Via CI/CD Pipeline

The application is automatically deployed via GitHub Actions when changes are pushed to the `aim/` directory or Helm chart.

### Via Helm CLI

```bash
helm upgrade --install aim ./kubernetes/apps \
  --namespace default \
  --create-namespace \
  --set image.repository=<ECR_URI> \
  --set image.tag=<TAG>
```

### Via ArgoCD

ArgoCD automatically syncs this Helm chart from the Git repository. The chart is configured in `kubernetes/argocd/application.yaml`.

## Configuration

### Values File

Edit `values.yaml` to customize:
- Image repository and tag
- Replica count
- Resource limits
- Ingress configuration
- Persistent storage settings

### Override Values

```bash
helm upgrade --install aim ./kubernetes/apps \
  --set replicaCount=2 \
  --set resources.limits.memory=4Gi
```

## Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `""` |
| `image.tag` | Container image tag | `"latest"` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `ClusterIP` |
| `ingress.enabled` | Enable ingress | `true` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage size | `10Gi` |
| `resources.requests.cpu` | CPU request | `200m` |
| `resources.requests.memory` | Memory request | `512Mi` |
| `resources.limits.cpu` | CPU limit | `1000m` |
| `resources.limits.memory` | Memory limit | `2Gi` |

## Deployment

The chart deploys:
- **Deployment**: Aim application with health checks
- **Service**: ClusterIP service on port 80
- **Ingress**: TLS-enabled ingress with ExternalDNS and CertManager
- **PVC**: Persistent volume for Aim data (10Gi)

## Access

After deployment, Aim is accessible at:
- **HTTPS**: https://eks.roodyadamsapp.com
- **HTTP**: Automatically redirected to HTTPS

## Upgrading

```bash
helm upgrade aim ./kubernetes/apps \
  --set image.tag=<NEW_TAG>
```

## Uninstalling

```bash
helm uninstall aim --namespace default
```

Note: PVC will remain unless manually deleted.
