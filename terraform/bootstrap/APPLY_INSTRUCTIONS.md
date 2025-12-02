# Bootstrap Terraform Apply Instructions

## Prerequisites
- AWS credentials configured
- S3 bucket for Terraform state (same as main Terraform)
- DynamoDB table for state locking (same as main Terraform)

## Steps to Apply

1. **Initialize Terraform with backend:**
   ```bash
   cd terraform/bootstrap
   terraform init \
     -backend-config="bucket=<YOUR_S3_BUCKET>" \
     -backend-config="key=bootstrap/terraform.tfstate" \
     -backend-config="region=eu-west-2" \
     -backend-config="dynamodb_table=<YOUR_DYNAMODB_TABLE>" \
     -backend-config="encrypt=true"
   ```

2. **Review the plan:**
   ```bash
   terraform plan
   ```

3. **Apply the changes:**
   ```bash
   terraform apply
   ```

4. **Get the GitHub Actions Role ARN:**
   ```bash
   terraform output github_actions_role_arn
   ```

5. **Update GitHub Secret:**
   - Go to: GitHub Repository → Settings → Secrets and variables → Actions
   - Update `AWS_ROLE_ARN` with the ARN from step 4

## What Will Be Created

- ECR Repository (if not exists)
- GitHub OIDC Provider
- GitHub Actions IAM Role with OIDC trust
- ECR Policy attached to GitHub Actions role

## Note

The bootstrap uses a separate state file (`bootstrap/terraform.tfstate`) so it persists even when main infrastructure is destroyed.
