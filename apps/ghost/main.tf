terraform {
  backend "gcs" {
    bucket="pechenikov_cluster_state"
    prefix="application-layer"
  }
}

data "google_container_cluster" "cluster" {
  name     = var.project_id
  location = var.zone
  project  = var.project_id
}

resource "kubernetes_namespace" "application" {
  metadata {
    name = "application"
  }
}

resource "helm_release" "ghost" {
  depends_on = [kubernetes_namespace.application]
  name       = "ghost"
  namespace  = "application"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "ghost"
  version    = "19.2.4" # or latest available

  values = [
    file("ghost-values.yaml")
  ]
}