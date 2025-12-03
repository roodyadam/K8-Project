terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "4.8.3"

  create_namespace = true
  wait             = false
  atomic           = false
  cleanup_on_fail  = false
  timeout          = 300

  values = [
    file("${path.root}/../kubernetes/nginx-ingress/helm-values.yaml")
  ]

  set {
    name  = "controller.service.waitForLoadBalancer"
    value = "false"
  }

  depends_on = [var.cluster_endpoint]

  lifecycle {
    ignore_changes = [version]
  }
}

resource "null_resource" "wait_for_loadbalancer_cleanup" {
  triggers = {
    release_name = helm_release.nginx_ingress.name
    namespace    = helm_release.nginx_ingress.namespace
    aws_region   = var.aws_region
    cluster_name = var.cluster_name
    vpc_name     = "${var.project_name}-${var.environment}-vpc"
  }

  depends_on = [helm_release.nginx_ingress]

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -e
      AWS_REGION="${self.triggers.aws_region}"
      CLUSTER_NAME="${self.triggers.cluster_name}"
      VPC_NAME="${self.triggers.vpc_name}"
      
      VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" \
        --query 'cluster.resourcesVpcConfig.vpcId' --output text 2>/dev/null || echo "")
      
      if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then
        VPC_ID=$(aws ec2 describe-vpcs \
          --filters "Name=tag:Name,Values=$VPC_NAME" \
          --query 'Vpcs[0].VpcId' --region "$AWS_REGION" --output text 2>/dev/null || echo "")
      fi
      
      if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
        ELB_LIST=$(aws elb describe-load-balancers --region "$AWS_REGION" \
          --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" \
          --output text 2>/dev/null || echo "")
        
        if [ -n "$ELB_LIST" ] && [ "$ELB_LIST" != "None" ]; then
          for ELB in $ELB_LIST; do
            aws elb delete-load-balancer --load-balancer-name "$ELB" --region "$AWS_REGION" || true
          done
        fi
        
        SG_LIST=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=k8s-elb-*" \
          --query 'SecurityGroups[*].GroupId' --region "$AWS_REGION" --output text 2>/dev/null || echo "")
        
        if [ -n "$SG_LIST" ] && [ "$SG_LIST" != "None" ]; then
          for SG in $SG_LIST; do
            ENI_COUNT=$(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$SG" \
              --region "$AWS_REGION" --query 'length(NetworkInterfaces)' --output text 2>/dev/null || echo "0")
            if [ "$ENI_COUNT" = "0" ]; then
              aws ec2 delete-security-group --group-id "$SG" --region "$AWS_REGION" || true
            fi
          done
        fi
        
        sleep 10
      fi
    EOT
  }
}