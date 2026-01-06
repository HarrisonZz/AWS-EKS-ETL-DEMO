# --- 1. Namespaces (只留 bootstrap 需要的) ---
resource "kubernetes_namespace_v1" "namespaces" {
  for_each = toset(["argocd", "ingress-nginx"])
  metadata {
    name = each.key
  }
}

# --- 2. Ingress Controller (流量入口；後續 ArgoCD/Grafana/Airflow 都靠它) ---
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.namespaces["ingress-nginx"].metadata[0].name
  wait       = true

  # 建議：讓 LoadBalancer 有固定 scope（可依需求調整）
  # values = [yamlencode({ controller = { service = { type = "LoadBalancer" }}})]
}

# --- 3. ArgoCD (只裝本體，交給它去裝其他平台元件) ---
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.namespaces["argocd"].metadata[0].name
  wait       = true

  values = [
    yamlencode({
      server = {
        service = { type = "ClusterIP" }
      }
    })
  ]

  depends_on = [helm_release.ingress_nginx]
}

# --- 4. ArgoCD Ingress（讓你能從外部進 ArgoCD UI） ---
resource "kubernetes_ingress_v1" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace_v1.namespaces["argocd"].metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"              = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
      # ArgoCD server 預設是 https；這裡用 http backend（demo 方便）
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
    }
  }

  spec {
    rule {
      host = "argocd.local" # 你可改成自己的 domain / nip.io
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port { number = 80 }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}
