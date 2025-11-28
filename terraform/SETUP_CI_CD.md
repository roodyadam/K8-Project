# Setting Up CI/CD for Terraform

This guide walks you through setting up GitHub Actions to automatically deploy your Terraform infrastructure.

## Prerequisites

- AWS CLI configured with appropriate credentials
- GitHub repository with Actions enabled
- Your GitHub organization and repository name

## Step 1: Set Up GitHub OIDC and IAM Role

This creates the necessary AWS resources for GitHub Actions to authenticate.

```bash
cd terraform
./setup-github-oidc.sh <your-github-org> <your-repo-name>
```

**Example:**
```bash
./setup-github-oidc.sh roodyadam K8-Project
```

This script will:
- ✅ Create GitHub's OIDC provider in AWS (if it doesn't exist)
- ✅ Create IAM policy with Terraform permissions
- ✅ Create IAM role that trusts GitHub Actions
- ✅ Output the role ARN for GitHub secrets

**Note:** The script will save the role ARN to `github-actions-role-arn.txt` for reference.

## Step 2: Set Up S3 and DynamoDB Backend

Create the S3 bucket and DynamoDB table for Terraform state management.

```bash
./setup-backend.sh <bucket-name> <dynamodb-table-name>
```

**Example:**
```bash
./setup-backend.sh eks-terraform-state-123456 terraform-state-lock
```

**Important:** 
- S3 bucket names must be globally unique
- Use a unique bucket name (e.g., include your account ID or a random suffix)

This script will:
- ✅ Create S3 bucket with versioning and encryption
- ✅ Create DynamoDB table for state locking
- ✅ Configure proper security settings

## Step 3: Add GitHub Secrets

Add the following secrets to your GitHub repository:

1. Go to: `https://github.com/<org>/<repo>/settings/secrets/actions`
2. Click "New repository secret"
3. Add each secret:

### Required Secrets

#### `AWS_ROLE_ARN`
- **Value:** The IAM role ARN from Step 1
- **Found in:** `github-actions-role-arn.txt` (created by setup script)
- **Example:** `arn:aws:iam::123456789012:role/github-actions-terraform-role`

#### `TF_STATE_BUCKET`
- **Value:** The S3 bucket name from Step 2
- **Example:** `eks-terraform-state-123456`

#### `TF_STATE_LOCK_TABLE`
- **Value:** The DynamoDB table name from Step 2
- **Example:** `terraform-state-lock`

## Step 4: Verify Setup

### Check OIDC Provider
```bash
aws iam list-open-id-connect-providers
```

You should see `token.actions.githubusercontent.com` in the list.

### Check IAM Role
```bash
aws iam get-role --role-name github-actions-terraform-role
```

### Check S3 Bucket
```bash
aws s3 ls | grep <your-bucket-name>
```

### Check DynamoDB Table
```bash
aws dynamodb describe-table --table-name <your-table-name>
```

## Step 5: Test the Workflow

1. **Make a small change** to a Terraform file (or just add a comment)
2. **Commit and push** to the `main` branch
3. **Check GitHub Actions** tab to see the workflow run

The workflow will:
- ✅ Validate Terraform code
- ✅ Check formatting
- ✅ Create a plan
- ✅ Apply changes (only on main branch)

## Troubleshooting

### Workflow fails with "Access Denied"

**Problem:** IAM role doesn't have sufficient permissions

**Solution:** 
- Check the IAM policy attached to the role
- Ensure the policy includes all necessary AWS service permissions

### Workflow fails with "Cannot assume role"

**Problem:** OIDC trust relationship not configured correctly

**Solution:**
- Verify the OIDC provider exists: `aws iam list-open-id-connect-providers`
- Check the role's trust policy matches your GitHub org/repo
- Ensure GitHub repository name matches exactly (case-sensitive)

### Workflow fails with "Bucket not found"

**Problem:** S3 bucket name in secret doesn't match actual bucket

**Solution:**
- Verify bucket exists: `aws s3 ls`
- Check the `TF_STATE_BUCKET` secret value matches exactly

### Workflow fails with "Table not found"

**Problem:** DynamoDB table name in secret doesn't match actual table

**Solution:**
- Verify table exists: `aws dynamodb list-tables`
- Check the `TF_STATE_LOCK_TABLE` secret value matches exactly

## Security Best Practices

1. **Least Privilege:** The IAM policy grants broad permissions for Terraform. In production, consider restricting to specific resources.

2. **Branch Protection:** Enable branch protection on `main` to require PR reviews before merging.

3. **Workflow Permissions:** The workflow uses OIDC (no long-lived credentials), which is more secure than access keys.

4. **State Encryption:** S3 bucket encryption is enabled by default in the setup script.

5. **State Locking:** DynamoDB table prevents concurrent Terraform runs.

## Next Steps

After CI/CD is set up:
- Monitor workflow runs in GitHub Actions
- Review Terraform plans before they're applied
- Set up notifications for workflow failures
- Consider adding Terraform plan comments to PRs

## Quick Reference

```bash
# Setup OIDC and IAM role
./setup-github-oidc.sh <org> <repo>

# Setup S3 and DynamoDB
./setup-backend.sh <bucket> <table>

# Get role ARN (for GitHub secret)
cat github-actions-role-arn.txt
```

