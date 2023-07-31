resource "kubernetes_namespace" "wordpress" {
    depends_on = [google_container_node_pool.cluster_pool]
    metadata {
        name = "wordpress"
    }
}

resource "kubernetes_deployment" "wordpress" {
  depends_on = [google_container_node_pool.cluster_pool]
  metadata {
    name      = "wordpress"
    namespace = "wordpress"

    labels = {
      app = "wordpress"
    }
  }

  spec {
    replicas = 0

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }

      spec {
        container {
          name  = "wordpress"
          image = "${var.GCP_GCR_HOST}/${var.GCP_PROJECT_ID}/wordpress:latest"

          port {
            name           = "http"
            container_port = 80
            protocol       = "TCP"
          }

          env {
            name  = "DB_HOST"
            value = google_sql_database_instance.wordpress_db.private_ip_address
          }
          env {
            name  = "DB_NAME"
            value = google_sql_database.wordpress.name
          }
          env {
            name  = "DB_USER"
            value = google_sql_user.wordpress_db_user.name
          }
          env {
            name  = "DB_PASSWORD"
            value = google_sql_user.wordpress_db_user.password
          }

          resources {
            requests = {
              cpu = "50m"
              memory = "120Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/wp-includes/images/blank.gif"
              port = 80
            }
            initial_delay_seconds = 15
            timeout_seconds       = 1
            period_seconds        = 20
            success_threshold     = 1
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/wp-includes/images/blank.gif"
              port = 80
            }
            initial_delay_seconds = 5
            timeout_seconds       = 1
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }

          image_pull_policy = "Always"
        }
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "1"
        max_surge       = "3"
      }
    }
  }
}

resource "kubernetes_service" "wordpress" {
  depends_on = [google_container_node_pool.cluster_pool]
  metadata {
    name      = "wordpress"
    namespace = "wordpress"
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\":false}"
    }
  }

  spec {
    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "wordpress"
    }

    type = "NodePort"
  }
}

resource "google_compute_global_address" "wordpress_ip" {
  name   = "wordpress-ip"
}

resource "kubernetes_ingress_v1" "wordpress" {
  depends_on = [google_container_node_pool.cluster_pool]
  metadata {
    name      = "wordpress"
    namespace = "wordpress"
    annotations = {
      "ingress.kubernetes.io/ingress.global-static-ip-name" = "wordpress-ip"
    }
  }

  spec {
    default_backend {
      service {
        name = "wordpress"
        port {
          number = 80
        }
      }
    }
    rule {
      http {
        path {
          path = "/*"
          backend {
            service {
              name = "wordpress"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Outputs
output "wordpress_ip" {
  value = google_compute_global_address.wordpress_ip.address
}