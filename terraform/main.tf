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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
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

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        var.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones != null ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 3)

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = var.tags
}

module "iam" {
  source = "./modules/iam"

  project_name             = var.project_name
  environment              = var.environment
  cluster_name             = var.cluster_name
  aws_region               = var.aws_region
  aws_account_id           = data.aws_caller_identity.current.account_id
  github_actions_role_name = "github-actions-terraform-role"

  tags = var.tags
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr

  tags = var.tags
}

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

  endpoint_public_access = var.endpoint_public_access
  public_access_cidrs    = var.public_access_cidrs
  aws_account_id         = data.aws_caller_identity.current.account_id

  tags = var.tags
}

resource "kubectl_manifest" "aws_auth" {
  depends_on = [module.eks]

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "aws-auth"
      namespace = "kube-system"
    }
    data = {
      mapRoles = yamlencode([
        {
          rolearn  = module.iam.node_group_role_arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups = [
            "system:bootstrappers",
            "system:nodes"
          ]
        }
      ])
      mapUsers = yamlencode([
        {
          userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          username = "admin"
          groups   = ["system:masters"]
        }
      ])
    }
  })
}

module "nginx_ingress" {
  source = "./modules/nginx-ingress"

  cluster_endpoint = module.eks.cluster_endpoint

  depends_on = [module.eks]
}

module "argocd" {
  source = "./modules/argocd"

  cluster_endpoint = module.eks.cluster_endpoint
  cluster_name     = var.cluster_name
  aws_region       = var.aws_region

  depends_on = [module.eks, module.nginx_ingress]
}

module "prometheus" {
  source = "./modules/prometheus"

  cluster_endpoint = module.eks.cluster_endpoint

  depends_on = [module.eks, module.nginx_ingress]
}

module "grafana" {
  source = "./modules/grafana"

  prometheus_service = module.prometheus.prometheus_service

  depends_on = [module.prometheus]
}
