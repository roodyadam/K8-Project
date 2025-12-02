output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.aim.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.aim.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.aim.name
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = var.github_actions_role_name != null && var.github_repo != null ? aws_iam_role.github_actions[0].arn : null
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = var.github_actions_role_name != null && var.github_repo != null ? aws_iam_openid_connect_provider.github[0].arn : null
}


