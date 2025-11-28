# Remote backend configuration for Terraform state
# This file is used by GitHub Actions to configure the S3 backend
# The actual backend configuration is passed via -backend-config flags in CI/CD

terraform {
  backend "s3" {
    # Backend configuration is provided via -backend-config flags
    # This allows different backends for different environments
  }
}

