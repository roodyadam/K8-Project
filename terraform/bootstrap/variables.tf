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

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "eks-project-aim"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role (optional)"
  type        = string
  default     = null
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' (e.g., 'roodyadam/K8-Project')"
  type        = string
  default     = null
}


