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
  timeout          = 900

  values = [
    file("${path.root}/../kubernetes/nginx-ingress/helm-values.yaml")
  ]

  depends_on = [var.cluster_endpoint]
}

