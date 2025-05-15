resource "kubernetes_namespace_v1" "service_ns" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_account_v1" "service_account" {
  metadata {
    name      = var.create_namespace ? kubernetes_namespace_v1.service_ns[0].metadata[0].name : var.namespace
    namespace = var.namespace
  }
}

resource "kubernetes_secret_v1" "service_account_token_secret" {
  metadata {
    name      = var.service_account_token_secret_name
    namespace = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.service_account.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

resource "time_sleep" "secret_generation" {
  depends_on = [
    kubernetes_secret_v1.service_account_token_secret
  ]
  create_duration = "5s"
}

data "kubernetes_secret_v1" "post_generation_secret" {
  depends_on = [
    time_sleep.secret_generation
  ]
  metadata {
    name      = var.service_account_token_secret_name
    namespace = var.namespace
  }
}
