resource "kubectl_manifest" "argocd_project_system" {
  yaml_body = file("${path.module}/files/argocd-project-system.yaml")
}

resource "kubectl_manifest" "argocd_app_system-app-of-apps" {
  yaml_body = file("${path.module}/files/argocd-app-system-app-of-apps.yaml")
}

resource "kubectl_manifest" "argocd_project_root" {
  count     = var.bootstrap_mode == "full" ? 1 : 0
  yaml_body = file("${path.module}/files/argocd-project-root.yaml")
}

resource "kubectl_manifest" "argocd_app_root-app-of-apps" {
  count     = var.bootstrap_mode == "full" ? 1 : 0
  yaml_body = file("${path.module}/files/argocd-app-root-app-of-apps.yaml")
}

