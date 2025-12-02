terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "55.5.0"

  create_namespace = true
  wait             = false
  atomic           = false
  cleanup_on_fail  = false
  timeout          = 300

  values = [
    file("${path.root}/../kubernetes/monitoring/prometheus/values.yaml")
  ]

  depends_on = [var.cluster_endpoint]
}

resource "kubectl_manifest" "nginx_servicemonitor" {
  depends_on = [helm_release.prometheus]

  yaml_body = file("${path.root}/../kubernetes/monitoring/prometheus/servicemonitor-nginx.yaml")
}

