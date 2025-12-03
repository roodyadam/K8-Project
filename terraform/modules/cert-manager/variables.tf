variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "acme_email" {
  description = "Email address for Let's Encrypt ACME registration"
  type        = string
  default     = "admin@example.com"
}


