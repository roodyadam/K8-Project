#!/bin/bash

# Script to import existing IAM resources into Terraform state
# Run this after terraform init with backend configured

set -e

echo "🔧 Importing existing IAM resources into Terraform state..."
echo ""

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/eks-project-dev-cluster-autoscaler-policy"

echo "📋 Importing IAM resources..."
echo ""

# Import cluster role
echo "1. Importing EKS cluster role..."
terraform import module.iam.aws_iam_role.cluster eks-project-dev-eks-cluster-role || echo "⚠️  Cluster role may already be imported"

# Import node group role
echo "2. Importing EKS node group role..."
terraform import module.iam.aws_iam_role.node_group eks-project-dev-eks-node-group-role || echo "⚠️  Node group role may already be imported"

# Import cluster autoscaler policy
echo "3. Importing cluster autoscaler policy..."
terraform import module.iam.aws_iam_policy.cluster_autoscaler "${POLICY_ARN}" || echo "⚠️  Policy may already be imported"

echo ""
echo "✅ Import complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Run: terraform plan"
echo "  2. Verify the plan looks correct"
echo "  3. Run: terraform apply"

