# GitHub Actions Workflows

## Terraform Workflow

The `terraform.yml` workflow automates Terraform deployments for EKS and AWS resources.

### Features

- ✅ **Validation**: Validates and formats Terraform code before deployment
- ✅ **Remote State**: Uses S3 + DynamoDB for state management and locking
- ✅ **Error Handling**: Fails fast on validation errors, shows plan status
- ✅ **Security**: Uses OIDC for AWS authentication (no long-lived credentials)
- ✅ **Efficiency**: Only runs on Terraform changes, applies only on main branch

### Setup

#### 1. Create S3 Bucket and DynamoDB Table

Run the setup script:

```bash
cd terraform
./setup-backend.sh <bucket-name> <dynamodb-table-name>
```

Or manually:
- Create S3 bucket with versioning and encryption enabled
- Create DynamoDB table with `LockID` as partition key (PAY_PER_REQUEST)

#### 2. Configure GitHub Secrets

Add these secrets in your GitHub repository settings:

- `AWS_ROLE_ARN`: IAM role ARN for GitHub Actions (with OIDC trust)
- `TF_STATE_BUCKET`: S3 bucket name for Terraform state
- `TF_STATE_LOCK_TABLE`: DynamoDB table name for state locking

#### 3. Create IAM Role for GitHub Actions

The IAM role should:
- Trust GitHub's OIDC provider
- Have permissions to:
  - Access S3 bucket (read/write)
  - Access DynamoDB table (read/write)
  - Create/manage EKS and related AWS resources

Example trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
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
    }
  ]
}
```

### Workflow Behavior

- **On Pull Request**: Validates and plans (no apply)
- **On Push to Main**: Validates, plans, and applies
- **Manual Trigger**: Can be triggered manually via workflow_dispatch

### Workflow Steps

1. **Checkout**: Gets the code
2. **Configure AWS**: Sets up AWS credentials via OIDC
3. **Setup Terraform**: Installs Terraform
4. **Terraform Init**: Initializes with S3 backend
5. **Terraform Validate**: Validates syntax and configuration
6. **Terraform Format Check**: Ensures code is formatted
7. **Terraform Plan**: Creates execution plan
8. **Terraform Apply**: Applies changes (only on main branch)

### Local Development

To use the remote backend locally:

```bash
cd terraform
terraform init \
  -backend-config="bucket=<your-bucket>" \
  -backend-config="key=eks-cluster/terraform.tfstate" \
  -backend-config="region=eu-west-2" \
  -backend-config="dynamodb_table=<your-table>" \
  -backend-config="encrypt=true"
```

