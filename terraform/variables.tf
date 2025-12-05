variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "eks-project"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use. If null, will use all available AZs in the region"
  type        = list(string)
  default     = null
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_capacity" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 5
}

variable "disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "acme_email" {
  description = "Email address for Let's Encrypt ACME registration (must be a valid email domain)"
  type        = string
  default     = "admin@roodyadamsapp.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.acme_email)) && !can(regex("@example\\.com$", var.acme_email))
    error_message = "acme_email must be a valid email address and cannot use example.com domain."
  }
}

variable "external_dns_domain_filters" {
  description = "List of domains to filter DNS records for ExternalDNS"
  type        = list(string)
  default     = []
}

variable "external_dns_policy" {
  description = "ExternalDNS policy (sync, upsert-only, create-only)"
  type        = string
  default     = "sync"
}

variable "argocd_admin_password_bcrypt" {
  description = "Bcrypt-hashed password for ArgoCD admin user"
  type        = string
  sensitive   = true
  # No default - must be provided via terraform.tfvars or environment variable
}
