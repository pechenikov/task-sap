output "host" {
  value = "${google_container_cluster.cluster.endpoint}"
  sensitive = true
}

output "client_certificate" {
  value = "${google_container_cluster.cluster.master_auth.0.client_certificate}"
  sensitive = true
}

output "client_key" {
  value = "${google_container_cluster.cluster.master_auth.0.client_key}"
  sensitive = true
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.cluster.master_auth.0.cluster_ca_certificate}"
  sensitive = true
}

output "token" {
  value = "${data.google_client_config.default.access_token}"
  sensitive = true
}

# output "loki_service_account_key" {
#   value = jsonencode(data.google_service_account_key.loki)
# }

# output "storage_access_key" {
#   value = azurerm_storage_account.storage.primary_access_key
# }

# output "minio_service_account_key" {
#   value = data.google_service_account_key.minio
# }