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