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

resource "helm_release" "wordpress" {
  depends_on = [kubernetes_namespace.application]
  name       = "wordpress"
  namespace = "application"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "wordpress"
  version    = "18.1.7"

  values = [file("${path.module}/values.yaml")]
}