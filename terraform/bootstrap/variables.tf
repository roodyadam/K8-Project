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


