resource "kubernetes_manifest" "argocd_project_system" {
  manifest = yamldecode(file("${path.module}/files/argocd-project-system.yaml"))
}

resource "kubernetes_manifest" "argocd_app_system-app-of-apps" {
  manifest = yamldecode(file("${path.module}/files/argocd-app-system-app-of-apps.yaml"))
}

resource "kubernetes_manifest" "argocd_project_root" {
  count    = var.bootstrap_mode == "full" ? 1 : 0
  manifest = yamldecode(file("${path.module}/files/argocd-project-root.yaml"))
}

resource "kubernetes_manifest" "argocd_app_root-app-of-apps" {
  count    = var.bootstrap_mode == "full" ? 1 : 0
  manifest = yamldecode(file("${path.module}/files/argocd-app-root-app-of-apps.yaml"))
}

