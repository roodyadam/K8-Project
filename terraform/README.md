# EKS Infrastructure with Terraform

This Terraform configuration provisions a complete AWS EKS (Elastic Kubernetes Service) cluster with best practices for networking, security, and scalability.

## Architecture

The infrastructure includes:

- **VPC Module**: Creates a VPC with public and private subnets across multiple availability zones
- **IAM Module**: Sets up IAM roles for EKS cluster and worker nodes with necessary permissions
- **Security Groups Module**: Configures security groups for cluster and node communication
- **EKS Module**: Provisions the EKS cluster with managed node groups

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.5.0 installed
3. kubectl installed (for cluster interaction after deployment)
4. AWS account with permissions to create:
   - VPCs, subnets, NAT gateways
   - EKS clusters
   - IAM roles and policies
   - EC2 instances
   - Security groups

## Quick Start

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your values:**
   - Set your AWS region
   - Customize cluster name, project name, etc.
   - Adjust node instance types and scaling configuration

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the execution plan:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```

6. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --region <your-region> --name <cluster-name>
   ```

## State Management

The Terraform state is currently configured for local storage. For production use, uncomment and configure the S3 backend in `main.tf`:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "eks-cluster/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

You'll need to create:
- An S3 bucket for state storage
- A DynamoDB table for state locking

## Module Structure

```
terraform/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variables
├── outputs.tf             # Output values
├── terraform.tfvars.example  # Example variable values
└── modules/
    ├── vpc/               # VPC and networking module
    ├── iam/               # IAM roles and policies module
    ├── security-groups/   # Security groups module
    └── eks/               # EKS cluster module
```

## Key Features

- **High Availability**: Multi-AZ deployment with public and private subnets
- **Security**: 
  - Private subnets for worker nodes
  - Security groups with least-privilege access
  - KMS encryption for secrets
  - Control plane logging enabled
- **Scalability**: Configurable auto-scaling node groups
- **Cost Optimization**: Optional single NAT gateway configuration

## Outputs

After deployment, Terraform will output:
- Cluster endpoint and certificate authority data
- VPC and subnet IDs
- Security group IDs
- kubectl configuration command

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will delete all resources created by Terraform, including the EKS cluster and all workloads.

## Next Steps

After infrastructure is deployed:
1. Install cluster autoscaler (if enabled)
2. Set up ArgoCD for GitOps
3. Configure monitoring with Prometheus and Grafana
4. Set up dynamic DNS and SSL/TLS certificates
5. Deploy your application

