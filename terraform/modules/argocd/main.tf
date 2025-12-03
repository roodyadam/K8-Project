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

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "7.6.6"

  create_namespace = true
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      configs = {
        secret = {
          argocdServerAdminPassword = "$2a$10$U0JAoW.3.V7.W6kivYanw.inJXqDaU0RETE97noRfKK/INqdQma2O"
        }
      }
      server = {
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled = false
        }
        extraArgs = [
          "--insecure"
        ]
        config = {
          url = "https://argocd.roodyadamsapp.com"
        }
      }
    })
  ]

  depends_on = [var.cluster_endpoint]
}

resource "kubectl_manifest" "argocd_application" {
  depends_on = [helm_release.argocd]
  yaml_body  = file("${path.root}/../kubernetes/argocd/application.yaml")
}

resource "kubectl_manifest" "argocd_ingress" {
  depends_on = [helm_release.argocd]
  yaml_body  = file("${path.root}/../kubernetes/argocd/ingress.yaml")
}

resource "kubectl_manifest" "argocd_certificate" {
  depends_on = [helm_release.argocd]
  yaml_body  = file("${path.root}/../kubernetes/argocd/certificate.yaml")
}