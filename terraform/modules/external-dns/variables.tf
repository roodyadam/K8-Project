variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for ExternalDNS"
  type        = string
  default     = "external-dns"
}

variable "domain_filters" {
  description = "List of domains to filter DNS records"
  type        = list(string)
  default     = []
}

variable "policy" {
  description = "ExternalDNS policy (sync, upsert-only, create-only)"
  type        = string
  default     = "sync"
}

variable "txt_owner_id" {
  description = "TXT record owner ID (optional, defaults to cluster name)"
  type        = string
  default     = null
}

variable "log_level" {
  description = "Log level for ExternalDNS"
  type        = string
  default     = "info"
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider (optional, will be auto-discovered if not provided)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}


