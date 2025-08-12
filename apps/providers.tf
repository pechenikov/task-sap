data "google_client_config" "default" {
}

provider "google" {
  credentials = file("${path.module}/../gke-sa-key.json")
  project     = var.project_id
  zone        = var.zone
}

provider google-beta {
  credentials = file("${path.module}/../gke-sa-key.json")
  project     = var.project_id
  zone        = var.zone
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}


provider "helm" {
  kubernetes = {
    config_path = "~/.kube/pechenikov-cluster"
  }
}