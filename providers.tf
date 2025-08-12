data "google_client_config" "default" {
}

provider "google" {
  credentials = file("${path.module}/gke-sa-key.json")
  project     = var.project_id
  zone        = var.zone
}

provider google-beta {
  credentials = file("${path.module}/gke-sa-key.json")
  project     = var.project_id
  zone        = var.zone
}

