provider "kubernetes" {
  host                   = google_container_cluster.cluster.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_namespace" "application" {
  metadata {
    name = "application"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "my-app"
    namespace = kubernetes_namespace.application.metadata[0].name
    labels = {
      app = "my-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }

      spec {
        container {
          name  = "my-app"
          image = "europe-west3-docker.pkg.dev/task-460410/task-repo/app:with-contracts"

          port {
            container_port = 8545
          }

          port {
            container_port = 8546
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "app_lb" {
  metadata {
    name      = "my-app-service"
    namespace = kubernetes_namespace.application.metadata[0].name
  }

  spec {
    selector = {
      app = "my-app"
    }

    port {
      name        = "rpc"
      port        = 8545
      target_port = 8545
      protocol    = "TCP"
    }

    port {
      name        = "ws"
      port        = 8546
      target_port = 8546
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}



