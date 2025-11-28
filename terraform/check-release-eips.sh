#!/bin/bash

# Script to check and release unused Elastic IPs
# This helps resolve the EIP limit issue

set -e

REGION="eu-west-2"

echo "🔍 Checking Elastic IPs in region: ${REGION}"
echo ""

# List all EIPs
echo "📋 All Elastic IPs:"
aws ec2 describe-addresses --region ${REGION} --output table

echo ""
echo "📋 Unused Elastic IPs (not associated with any resource):"
UNUSED_EIPS=$(aws ec2 describe-addresses --region ${REGION} --query 'Addresses[?AssociationId==null].[AllocationId,PublicIp]' --output text)

if [ -z "$UNUSED_EIPS" ]; then
  echo "  ✅ No unused EIPs found"
else
  echo "$UNUSED_EIPS" | while read -r allocation_id public_ip; do
    if [ ! -z "$allocation_id" ]; then
      echo "  - Allocation ID: $allocation_id, Public IP: $public_ip"
    fi
  done
  
  echo ""
  echo "⚠️  To release unused EIPs, run:"
  echo "$UNUSED_EIPS" | while read -r allocation_id public_ip; do
    if [ ! -z "$allocation_id" ]; then
      echo "  aws ec2 release-address --allocation-id $allocation_id --region ${REGION}"
    fi
  done
fi

echo ""
echo "📊 EIP Limit Information:"
echo "  Default limit: 5 Elastic IPs per region"
echo "  Current usage: $(aws ec2 describe-addresses --region ${REGION} --query 'length(Addresses)' --output text)"
echo ""
echo "💡 With single_nat_gateway = true, you only need 1 EIP"

