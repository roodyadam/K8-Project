# 🆘 Help Guide - K8s Project Setup

## Current Status

You're setting up an EKS cluster with NGINX Ingress Controller. Here's where you are and what to do next:

## ✅ What's Done

1. **Terraform Infrastructure Code** - Complete
   - VPC module with public/private subnets
   - EKS cluster module
   - IAM roles module
   - Security groups module
   - All in `/terraform` directory

2. **NGINX Ingress Controller Configuration** - Complete
   - Helm values configured
   - Deployment scripts ready
   - Pre-deployment checks created
   - All in `/kubernetes/nginx-ingress` directory

3. **Prerequisites Installed**
   - ✅ kubectl installed
   - ✅ Helm installed (v4.0.1)
   - ✅ AWS credentials configured

## ⚠️ What's Needed

**EKS Cluster is not deployed yet.** You need to create it first.

## 🚀 Step-by-Step Guide

### Step 1: Deploy EKS Cluster with Terraform

```bash
# Navigate to terraform directory
cd /Users/roodyadams/Documents/K8s-Project/terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values (optional - defaults work)
# You can use: nano terraform.tfvars or your preferred editor

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy the infrastructure (this takes 15-20 minutes)
terraform apply
```

**Important:** Type `yes` when prompted to confirm the deployment.

### Step 2: Configure kubectl to Connect to Your Cluster

After Terraform finishes, you'll get output with the cluster name. Then run:

```bash
# Replace <region> and <cluster-name> with your values
# Default region from your AWS config is: eu-west-2
# Default cluster name from terraform.tfvars.example is: eks-cluster

aws eks update-kubeconfig --region eu-west-2 --name eks-cluster
```

Or use the command from Terraform output:
```bash
# Terraform will output a command like:
# aws eks update-kubeconfig --region us-east-1 --name eks-cluster
```

### Step 3: Verify Cluster Connection

```bash
# Check cluster info
kubectl cluster-info

# Check nodes are ready
kubectl get nodes

# Should show your worker nodes
```

### Step 4: Deploy NGINX Ingress Controller

```bash
# Navigate to nginx-ingress directory
cd /Users/roodyadams/Documents/K8s-Project/kubernetes/nginx-ingress

# Run pre-deployment checks
./pre-deploy-checks.sh

# If checks pass, deploy
./deploy.sh
```

### Step 5: Get LoadBalancer Address

```bash
# Get the external address
kubectl get service -n ingress-nginx ingress-nginx-controller

# The EXTERNAL-IP or HOSTNAME is your ingress endpoint
```

## 📋 Quick Commands Reference

### Check Terraform State
```bash
cd terraform
terraform show
terraform output
```

### Check Cluster Status
```bash
aws eks describe-cluster --name eks-cluster --region eu-west-2
```

### List All EKS Clusters
```bash
aws eks list-clusters --region eu-west-2
```

### Check NGINX Ingress Status
```bash
kubectl get pods -n ingress-nginx
kubectl get service -n ingress-nginx
kubectl get ingressclass
```

## 🐛 Common Issues & Solutions

### Issue: "terraform: command not found"
**Solution:** Install Terraform
```bash
# macOS
brew install terraform

# Or download from: https://www.terraform.io/downloads
```

### Issue: "Error: No valid credential sources found"
**Solution:** Configure AWS credentials
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format
```

### Issue: "Error creating EKS Cluster: UnauthorizedOperation"
**Solution:** Your AWS user needs EKS permissions. Add these IAM policies:
- AmazonEKSClusterPolicy
- AmazonEKSServicePolicy
- AmazonEC2FullAccess (or more restricted EC2 permissions)

### Issue: "kubectl: command not found"
**Solution:** Install kubectl
```bash
# macOS
brew install kubectl

# Or: https://kubernetes.io/docs/tasks/tools/
```

### Issue: LoadBalancer stuck in "pending"
**Solution:** 
1. Check AWS IAM permissions for the node group
2. Verify security groups allow traffic
3. Check AWS console for Load Balancer creation status

## 📚 File Locations

- **Terraform Config**: `/terraform/`
- **NGINX Ingress**: `/kubernetes/nginx-ingress/`
- **Documentation**: Check README.md files in each directory

## 🎯 What's Next After This?

Once NGINX Ingress is deployed:
1. Install CertManager for TLS certificates
2. Set up dynamic DNS
3. Configure monitoring (Prometheus/Grafana)
4. Set up ArgoCD for GitOps
5. Deploy your application

## 💡 Need More Help?

- Check the README.md files in each directory
- Review the pre-deployment checks output
- Check Terraform output for cluster details
- AWS EKS Documentation: https://docs.aws.amazon.com/eks/

