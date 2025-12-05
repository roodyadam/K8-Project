variable "cluster_endpoint" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "argocd_admin_password_bcrypt" {
  description = "Bcrypt-hashed password for ArgoCD admin user"
  type        = string
  sensitive   = true
}