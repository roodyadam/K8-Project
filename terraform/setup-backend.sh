#!/bin/bash

# Script to set up S3 bucket and DynamoDB table for Terraform remote state
# Run this once before using the Terraform backend

set -e

# Configuration
REGION="eu-west-2"
BUCKET_NAME="${1:-eks-terraform-state-$(date +%s)}"
LOCK_TABLE_NAME="${2:-terraform-state-lock}"
PROJECT_NAME="eks-project"

echo "🔧 Setting up Terraform remote backend..."
echo "  Region: ${REGION}"
echo "  S3 Bucket: ${BUCKET_NAME}"
echo "  DynamoDB Table: ${LOCK_TABLE_NAME}"
echo ""

# Create S3 bucket for state
echo "📦 Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
  --bucket ${BUCKET_NAME} \
  --region ${REGION} \
  --create-bucket-configuration LocationConstraint=${REGION} 2>/dev/null || \
  echo "Bucket may already exist"

# Enable versioning
echo "📝 Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Enable encryption
echo "🔒 Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
echo "🔐 Blocking public access..."
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table for state locking
echo "📊 Creating DynamoDB table for state locking..."
aws dynamodb create-table \
  --table-name ${LOCK_TABLE_NAME} \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${REGION} 2>/dev/null || \
  echo "Table may already exist"

# Wait for table to be active
echo "⏳ Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists \
  --table-name ${LOCK_TABLE_NAME} \
  --region ${REGION}

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "📋 Add these secrets to GitHub Actions:"
echo "  TF_STATE_BUCKET: ${BUCKET_NAME}"
echo "  TF_STATE_LOCK_TABLE: ${LOCK_TABLE_NAME}"
echo "  AWS_ROLE_ARN: <your-iam-role-arn-for-github-actions>"
echo ""
echo "💡 To use this backend locally, run:"
echo "  terraform init \\"
echo "    -backend-config=\"bucket=${BUCKET_NAME}\" \\"
echo "    -backend-config=\"key=eks-cluster/terraform.tfstate\" \\"
echo "    -backend-config=\"region=${REGION}\" \\"
echo "    -backend-config=\"dynamodb_table=${LOCK_TABLE_NAME}\" \\"
echo "    -backend-config=\"encrypt=true\""

