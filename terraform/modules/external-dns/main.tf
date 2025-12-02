terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Get EKS cluster OIDC issuer URL
data "aws_eks_cluster" "main" {
  name = var.cluster_name
}

# Get OIDC provider ARN from cluster
locals {
  oidc_provider_arn = var.oidc_provider_arn != null ? var.oidc_provider_arn : "arn:aws:iam::${var.aws_account_id}:oidc-provider/${replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}"
  oidc_issuer_url   = replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

# IAM Role for ExternalDNS Service Account (IRSA)
resource "aws_iam_role" "external_dns" {
  name = "${var.project_name}-${var.environment}-external-dns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer_url}:sub" = "system:serviceaccount:${var.namespace}:external-dns"
            "${local.oidc_issuer_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-external-dns-role"
    }
  )

  # Ensure OIDC provider exists before creating IAM role
  depends_on = [data.aws_eks_cluster.main]
}

# IAM Policy for ExternalDNS
resource "aws_iam_policy" "external_dns" {
  name        = "${var.project_name}-${var.environment}-external-dns-policy"
  description = "Policy for ExternalDNS to manage Route 53 DNS records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-external-dns-policy"
    }
  )
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

# Kubernetes Service Account for ExternalDNS
resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
    }
    labels = {
      app = "external-dns"
    }
  }

  depends_on = [var.cluster_endpoint]
}

# Deploy ExternalDNS via Helm
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = var.namespace
  version    = "1.14.0"

  create_namespace = true
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      provider = "aws"
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.external_dns.metadata[0].name
      }
      domainFilters = var.domain_filters
      policy        = var.policy
      txtOwnerId    = var.txt_owner_id != null ? var.txt_owner_id : var.cluster_name
      aws = {
        region = var.aws_region
      }
      logLevel  = var.log_level
      logFormat = "json"
    })
  ]

  depends_on = [
    kubernetes_service_account.external_dns,
    var.cluster_endpoint
  ]
}

