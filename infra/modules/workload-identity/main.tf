# 1. 建立 GCP Service Account (GSA)
resource "google_service_account" "sa" {
  account_id   = var.gsa_name
  display_name = "Service Account for ${var.gsa_name}"
  project      = var.project_id
}

# 2. 賦予 GCP SA 權限 (IAM Roles)
# 這裡使用迴圈 (for_each) 來支援傳入多個權限
resource "google_project_iam_member" "roles" {
  for_each = toset(var.roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# 3. 建立 K8s Service Account (KSA)
# 使用 v1 版本 (修正你之前遇到的 deprecated 警告)
resource "kubernetes_service_account_v1" "ksa" {
  metadata {
    name      = var.ksa_name
    namespace = var.namespace
    annotations = {
      # 關鍵：告訴 K8s 這個帳號對應到哪個 GCP SA
      "iam.gke.io/gcp-service-account" = google_service_account.sa.email
    }
  }
}

# 4. 綁定兩者 (Workload Identity Binding)
# 允許 KSA "扮演" GSA
resource "google_service_account_iam_member" "wi_bind" {
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.ksa_name}]"
}

# 1) 給 monitoring namespace 的 secrets reader 用的 GCP SA
resource "google_service_account" "monitoring_secrets_reader" {
  account_id   = "${var.project_id}-monitoring-secrets-reader"
  display_name = "Monitoring Secrets Reader"
}

# 2) 只允許讀特定 secret（比給整個 project 更小權限）
resource "google_secret_manager_secret_iam_member" "grafana_admin_reader" {
  project   = var.project_id
  secret_id = "grafana-admin" # 你在 GSM 的 secret 名稱
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.monitoring_secrets_reader.email}"
}

# 3) Workload Identity：允許 KSA 冒用這個 GCP SA
resource "google_service_account_iam_member" "grafana_wi_binding" {
  service_account_id = google_service_account.monitoring_secrets_reader.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/monitoring-secrets-sa]"
}
