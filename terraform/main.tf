terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote backend configuration is in backend.tf
  # Backend is configured via -backend-config flags in CI/CD
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
  # Filter to only EKS-supported zones (first 3 zones are typically supported)
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  # Use explicit zones if provided, otherwise use first 3 available zones (EKS-supported)
  availability_zones = var.availability_zones != null ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 3)

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = var.tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = var.cluster_name

  tags = var.tags
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr

  tags = var.tags
}

# EKS Cluster Module
module "eks" {
  source = "./modules/eks"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = var.cluster_name

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  cluster_service_role_arn = module.iam.cluster_role_arn
  node_group_role_arn      = module.iam.node_group_role_arn

  cluster_security_group_id = module.security_groups.cluster_security_group_id
  node_security_group_id    = module.security_groups.node_security_group_id

  kubernetes_version  = var.kubernetes_version
  node_instance_types = var.node_instance_types
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  disk_size           = var.disk_size

  enable_cluster_autoscaler = var.enable_cluster_autoscaler

  tags = var.tags
}

