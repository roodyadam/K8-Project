# Setting Up CI/CD for Terraform

This guide walks you through setting up GitHub Actions to automatically deploy your Terraform infrastructure.

## Prerequisites

- AWS CLI configured with appropriate credentials
- GitHub repository with Actions enabled
- Your GitHub organization and repository name

## Step 1: Set Up GitHub OIDC and IAM Role

This creates the necessary AWS resources for GitHub Actions to authenticate.

### Manual Setup

1. **Create GitHub OIDC Provider** (if it doesn't exist):
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
     --region eu-west-2
   ```

2. **Create IAM Policy**:
   ```bash
   aws iam create-policy \
     --policy-name github-actions-terraform-policy \
     --policy-document file://iam-policy.json
   ```

3. **Create IAM Role** with trust policy for your GitHub repository:
   ```bash
   # Replace <account-id>, <org>, <repo> with your values
   aws iam create-role \
     --role-name github-actions-terraform-role \
     --assume-role-policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:<org>/<repo>:*"
           }
         }
       }]
     }'
   ```

4. **Attach Policy to Role**:
   ```bash
   aws iam attach-role-policy \
     --role-name github-actions-terraform-role \
     --policy-arn arn:aws:iam::<account-id>:policy/github-actions-terraform-policy
   ```

5. **Get Role ARN**:
   ```bash
   aws iam get-role --role-name github-actions-terraform-role --query 'Role.Arn' --output text
   ```

## Step 2: Set Up S3 and DynamoDB Backend

Create the S3 bucket and DynamoDB table for Terraform state management.

### Manual Setup

1. **Create S3 Bucket**:
   ```bash
   # Replace <unique-bucket-name> with a globally unique name
   aws s3api create-bucket \
     --bucket <unique-bucket-name> \
     --region eu-west-2 \
     --create-bucket-configuration LocationConstraint=eu-west-2
   
   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket <unique-bucket-name> \
     --versioning-configuration Status=Enabled
   
   # Enable encryption
   aws s3api put-bucket-encryption \
     --bucket <unique-bucket-name> \
     --server-side-encryption-configuration '{
       "Rules": [{
         "ApplyServerSideEncryptionByDefault": {
           "SSEAlgorithm": "AES256"
         }
       }]
     }'
   ```

2. **Create DynamoDB Table**:
   ```bash
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region eu-west-2
   ```

**Important:** 
- S3 bucket names must be globally unique
- Use a unique bucket name (e.g., include your account ID or a random suffix)

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
# Get AWS Account ID
aws sts get-caller-identity --query Account --output text

# Get IAM Role ARN (for GitHub secret)
aws iam get-role --role-name github-actions-terraform-role --query 'Role.Arn' --output text

# List S3 buckets
aws s3 ls

# List DynamoDB tables
aws dynamodb list-tables
```

