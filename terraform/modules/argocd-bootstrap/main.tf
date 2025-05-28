resource "kubectl_manifest" "argocd_project_system" {
  apply_only = true
  yaml_body  = file("${path.module}/files/argocd-project-system.yaml")

  lifecycle {
    ignore_changes = [
      yaml_body
    ]
  }
}

resource "kubectl_manifest" "argocd_app_system-app-of-apps" {
  apply_only = true
  yaml_body  = file("${path.module}/files/argocd-app-system-app-of-apps.yaml")
  lifecycle {
    ignore_changes = [
      yaml_body
    ]
  }
}

resource "kubectl_manifest" "argocd_project_root" {
  count      = var.bootstrap_mode == "full" ? 1 : 0
  apply_only = true
  yaml_body  = file("${path.module}/files/argocd-project-root.yaml")
  lifecycle {
    ignore_changes = [
      yaml_body
    ]
  }
}

resource "kubectl_manifest" "argocd_app_root-app-of-apps" {
  count      = var.bootstrap_mode == "full" ? 1 : 0
  apply_only = true
  yaml_body  = file("${path.module}/files/argocd-app-root-app-of-apps.yaml")
  lifecycle {
    ignore_changes = [
      yaml_body
    ]
  }
}

