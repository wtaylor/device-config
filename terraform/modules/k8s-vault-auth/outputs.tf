output "service_account_token" {
  value = data.kubernetes_secret_v1.post_generation_secret.data["token"]
}
