output "gsa_email" {
  description = "The email of the created Google Service Account"
  value       = google_service_account.sa.email
}

output "ksa_name" {
  description = "The name of the created Kubernetes Service Account"
  value       = kubernetes_service_account_v1.ksa.metadata[0].name
}

output "monitoring_secrets_gcp_sa_email" {
  value = google_service_account.monitoring_secrets_reader.email
}
