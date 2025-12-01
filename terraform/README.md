# EKS Infrastructure with Terraform

Terraform configuration for AWS EKS cluster with GitOps automation.

## Architecture

- **VPC Module**: VPC with public and private subnets across multiple AZs
- **IAM Module**: IAM roles for EKS cluster and worker nodes
- **Security Groups Module**: Security groups for cluster and node communication
- **EKS Module**: EKS cluster with managed node groups
- **ArgoCD Module**: ArgoCD installation and configuration (GitOps)

## Prerequisites

- AWS CLI configured
- Terraform >= 1.5.0
- kubectl installed

## Quick Start

1. Configure variables in `terraform.tfvars`
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review plan:
   ```bash
   terraform plan
   ```
4. Apply:
   ```bash
   terraform apply
   ```

## State Management

State is stored in S3 backend (configured via CI/CD pipeline).

## Module Structure

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.tf
├── terraform.tfvars
└── modules/
    ├── vpc/
    ├── iam/
    ├── security-groups/
    ├── eks/
    └── argocd/
```

## Features

- Multi-AZ deployment
- Private subnets for worker nodes
- Security groups with least-privilege access
- KMS encryption
- Control plane logging
- Auto-scaling node groups
- GitOps with ArgoCD

## Cleanup

```bash
terraform destroy
```
