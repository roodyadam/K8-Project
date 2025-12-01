# ArgoCD GitOps Setup

ArgoCD is a declarative GitOps continuous delivery tool for Kubernetes. This setup is **fully automated via Terraform** - everything is managed through Infrastructure as Code with zero manual steps.

## Architecture

```
Git Repository (GitHub)
    ↓
Terraform (CI/CD Pipeline)
    ↓
EKS Cluster
    ↓
ArgoCD (installed via Terraform)
    ↓
Application (managed by ArgoCD from Git)
```

## GitOps Principles

✅ **Everything in Git**: ArgoCD installation, Application CRD, and Ingress are all defined in Git  
✅ **Fully Automated**: Terraform installs and manages ArgoCD automatically  
✅ **Zero Manual Steps**: Push to Git → CI/CD → Terraform → ArgoCD installed → Application deployed  
✅ **Self-Healing**: ArgoCD automatically reconciles cluster state with Git  
✅ **Reproducible**: Same Git state = same cluster state

## Components

### 1. ArgoCD Installation
- **Managed by**: Terraform (`terraform/modules/argocd/`)
- **Method**: Helm chart installed via Terraform Helm provider
- **Namespace**: `argocd` (created automatically)
- **Version**: Pinned to `7.6.6` for reproducibility

### 2. ArgoCD Application
- **Managed by**: Terraform (`terraform/modules/argocd/main.tf`)
- **Source**: GitHub repository `roodyadam/K8-Project`
- **Path**: `kubernetes/apps/` (Helm chart)
- **Destination**: EKS cluster, `default` namespace
- **Sync Policy**: Automated with self-healing and pruning

### 3. ArgoCD Ingress
- **Managed by**: Terraform (`terraform/modules/argocd/main.tf`)
- **Host**: `argocd.roodyadamsapp.com`
- **TLS**: Managed by CertManager
- **DNS**: Managed by ExternalDNS

## Deployment (Fully Automated)

### How It Works

1. **Push to Git**: Changes pushed to `main` branch
2. **CI/CD Pipeline**: GitHub Actions runs Terraform workflow
3. **Terraform Apply**: 
   - Creates EKS cluster (if needed)
   - Installs ArgoCD via Helm
   - Applies ArgoCD Application CRD
   - Applies ArgoCD Ingress
4. **ArgoCD Sync**: ArgoCD watches Git and automatically syncs application

### No Manual Steps Required

Everything is automated:
- ✅ ArgoCD installation → Terraform
- ✅ ArgoCD Application → Terraform
- ✅ ArgoCD Ingress → Terraform
- ✅ Application deployment → ArgoCD (from Git)

## Features

### Automated Sync
- ArgoCD automatically syncs when changes are pushed to the `main` branch
- Watches the `kubernetes/apps/` Helm chart
- Polls every 3 minutes (or configure webhook for instant sync)

### Self-Healing
- Automatically corrects any manual changes made to the cluster
- Reconciles cluster state with Git repository state
- Ensures desired state is always maintained

### Pruning
- Automatically removes resources that are deleted from Git
- Keeps cluster in sync with repository

## Configuration

### Sync Policy
- **Automated**: Enabled
- **Prune**: Enabled (removes deleted resources)
- **Self-Heal**: Enabled (corrects manual changes)
- **Retry**: 5 attempts with exponential backoff

### Sync Options
- **CreateNamespace**: Automatically creates namespace if it doesn't exist
- **PrunePropagationPolicy**: `foreground` (waits for resources to be deleted)
- **PruneLast**: Prunes resources last during sync

## Accessing ArgoCD

### Get Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### Access ArgoCD UI
- **URL**: https://argocd.roodyadamsapp.com
- **Username**: `admin`
- **Password**: (from command above)

## Monitoring

### Check Application Status
```bash
kubectl get application -n argocd
kubectl describe application aim-application -n argocd
```

### View Sync Status
```bash
kubectl get application aim-application -n argocd -o yaml
```

### ArgoCD CLI
```bash
brew install argocd
argocd login argocd.roodyadamsapp.com
argocd app get aim-application
argocd app sync aim-application
```

## Troubleshooting

### Application Not Syncing
```bash
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-repo-server
kubectl describe application aim-application -n argocd
```

### Sync Failures
```bash
kubectl describe application aim-application -n argocd
argocd app history aim-application
```

### Ingress Not Working
```bash
kubectl get pods -n ingress-nginx
kubectl describe ingress argocd-server-ingress -n argocd
```

## Best Practices

1. **Never manually edit resources** managed by ArgoCD
2. **Always commit changes to Git** first
3. **Use ArgoCD UI** to monitor deployments
4. **Review sync status** before making changes
5. **Use feature branches** for testing before merging to main

## GitOps Workflow

1. **Developer pushes changes** to `kubernetes/apps/` in Git
2. **Terraform pipeline** (if infrastructure changes) runs automatically
3. **ArgoCD detects change** (polls every 3 minutes or via webhook)
4. **ArgoCD syncs** the Helm chart to the cluster
5. **Application is updated** automatically

## Files

- `terraform/modules/argocd/main.tf` - ArgoCD Terraform module (installs ArgoCD, applies Application/Ingress)
- `kubernetes/argocd/application.yaml` - ArgoCD Application CRD (managed by Terraform)
- `kubernetes/argocd/ingress.yaml` - ArgoCD Ingress (managed by Terraform)

All managed via GitOps - no manual steps required!
