terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
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
  wait             = true
  wait_for_jobs    = false
  timeout          = 900

  values = [
    file("${path.root}/../kubernetes/nginx-ingress/helm-values.yaml")
  ]

  # Don't wait for LoadBalancer to provision (it can take 10-15 minutes)
  # This allows Helm to complete once pods are ready, LB will provision in background
  set {
    name  = "controller.service.waitForLoadBalancer"
    value = "false"
  }

  depends_on = [var.cluster_endpoint]
}
