#!/bin/bash
# Script to delete existing NGINX Ingress Helm release
# Run this before running terraform apply

set -e

echo "Configuring kubectl..."
aws eks update-kubeconfig --name eks-cluster --region eu-west-2

echo "Checking for existing NGINX Ingress Helm release..."
if helm list -n ingress-nginx | grep -q ingress-nginx; then
    echo "Found existing release. Deleting..."
    helm uninstall ingress-nginx -n ingress-nginx || true
    echo "Waiting for namespace cleanup..."
    sleep 10
    kubectl delete namespace ingress-nginx --ignore-not-found=true || true
    echo "✅ NGINX Ingress Helm release deleted"
else
    echo "No existing Helm release found"
fi

echo "✅ Ready for Terraform apply"

