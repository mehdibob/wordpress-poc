# Setup providers
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.74.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
  }
}

# Define providers and enable necessairy serices

provider "google" {
  project = var.GCP_PROJECT_ID
  credentials = file(var.SA_FILE)
}

module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.2"
  project_id = var.GCP_PROJECT_ID

  activate_apis = [
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "file.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

resource "time_sleep" "wait_for_services" {
  depends_on = [module.project-services]

  create_duration = "180s"
}

output "enabled_apis" {
  value  = module.project-services.enabled_apis
}

data "google_client_config" "current" {
}
provider "kubernetes" {
  host = "https://${google_container_cluster.cluster.endpoint}"
  token = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}