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

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring"
  version    = "7.3.7"

  create_namespace = true
  wait             = true
  timeout          = 600

  values = [
    file("${path.root}/../kubernetes/monitoring/grafana/values.yaml")
  ]

  depends_on = [var.prometheus_service]
}

resource "kubectl_manifest" "grafana_dashboards" {
  for_each = fileset("${path.root}/../kubernetes/monitoring/grafana/dashboards", "*.json")

  depends_on = [helm_release.grafana]

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "grafana-dashboard-${replace(each.key, ".json", "")}"
      namespace = "monitoring"
      labels = {
        grafana_dashboard = "1"
      }
    }
    data = {
      "${replace(each.key, ".json", "")}.json" = file("${path.root}/../kubernetes/monitoring/grafana/dashboards/${each.key}")
    }
  })
}

resource "kubectl_manifest" "grafana_ingress" {
  depends_on = [helm_release.grafana]

  yaml_body = file("${path.root}/../kubernetes/monitoring/grafana/ingress.yaml")
}

