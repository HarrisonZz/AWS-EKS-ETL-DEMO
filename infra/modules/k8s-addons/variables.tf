# ==========================================
# 1. 代碼中直接引用的變數 (Airflow / GCP 設定)
# ==========================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcs_bucket_name" {
  description = "存放 ETL 數據或 DAG 的 GCS Bucket 名稱"
  type        = string
}

variable "gcp_service_account_email" {
  description = "Airflow Workload Identity 綁定用的 GCP SA Email"
  type        = string
}

# ==========================================
# 2. 環境運行必要的變數 (Provider / 模組呼叫)
# ==========================================

variable "region" {
  description = "GCP 部署區域 (例如 asia-east1)"
  type        = string
  default     = "asia-east1"
}

variable "cluster_name" {
  description = "GKE 叢集名稱 (用於 Provider 驗證或命名標籤)"
  type        = string
  default     = "etl-demo-cluster"
}

variable "env_name" {
  description = "環境名稱 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "monitoring_secrets_gcp_sa_email" {
  description = "GCP Service Account email used by External Secrets Operator via Workload Identity to access Secret Manager (Secret Accessor)."
  type        = string
}

variable "external_secrets_gcp_sa_email" {
  description = "GCP Service Account email used by External Secrets Operator via Workload Identity to access Secret Manager."
  type        = string
}
