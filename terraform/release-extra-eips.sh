#!/bin/bash

# Script to release 2 extra EIPs to free up space for single NAT gateway
# This is needed when transitioning from multi-NAT to single-NAT setup

set -e

REGION="eu-west-2"

echo "🔧 Releasing extra EIPs for single NAT gateway setup..."
echo ""

# Get all NAT gateways
NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --region ${REGION} --filter "Name=state,Values=available" --query 'NatGateways[*].[NatGatewayId,AllocationId]' --output text)

if [ -z "$NAT_GATEWAYS" ]; then
  echo "✅ No NAT gateways found"
  exit 0
fi

echo "📋 Found NAT Gateways:"
echo "$NAT_GATEWAYS" | nl

echo ""
echo "⚠️  WARNING: This will delete NAT gateways and release their EIPs"
echo "   With single_nat_gateway = true, you only need 1 NAT gateway"
echo ""
read -p "Do you want to delete 2 NAT gateways? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Cancelled"
  exit 0
fi

# Delete 2 NAT gateways (keep the first one)
COUNT=0
echo "$NAT_GATEWAYS" | while read -r nat_id allocation_id; do
  if [ $COUNT -ge 2 ]; then
    break
  fi
  
  if [ ! -z "$nat_id" ]; then
    echo ""
    echo "🗑️  Deleting NAT Gateway: $nat_id"
    aws ec2 delete-nat-gateway --nat-gateway-id "$nat_id" --region ${REGION}
    
    echo "⏳ Waiting for NAT gateway to be deleted..."
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$nat_id" --region ${REGION}
    
    echo "🔓 Releasing EIP: $allocation_id"
    aws ec2 release-address --allocation-id "$allocation_id" --region ${REGION}
    
    echo "✅ NAT Gateway $nat_id deleted and EIP released"
    COUNT=$((COUNT + 1))
  fi
done

echo ""
echo "✅ Done! You now have 1 NAT gateway and 1 EIP"
echo "   Terraform can now create/update resources without hitting EIP limit"

