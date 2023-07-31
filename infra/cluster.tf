resource "google_service_account" "cluster_sa" {
  depends_on = [time_sleep.wait_for_services]
  account_id   = "cluster-sa"
  display_name = "Cluster Service Account"
}

resource "google_project_iam_binding" "editor_binding" {
  project = var.GCP_PROJECT_ID
  role    = "roles/editor"
  
  members = [
    "serviceAccount:${google_service_account.cluster_sa.email}",
    "serviceAccount:${var.GCP_PROJECT_NUM}@cloudbuild.gserviceaccount.com"

  ]
}

resource "google_container_cluster" "cluster" {
  depends_on = [time_sleep.wait_for_services]
  name                     = "cluster"
  location                 = "europe-west1-b"
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.test_vpc.id
  subnetwork               = google_compute_subnetwork.vm_subnet.id
  default_max_pods_per_node = 20
  default_snat_status {
    disabled       = "true"
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.vm_subnet.secondary_ip_range.0.range_name
    services_secondary_range_name = google_compute_subnetwork.vm_subnet.secondary_ip_range.1.range_name
  }
  private_cluster_config {
    enable_private_nodes    = "true"
    enable_private_endpoint = "false"
    master_ipv4_cidr_block  = "172.16.0.32/28"
    master_global_access_config {
      enabled             = "true"
    }
  }
  master_authorized_networks_config {
    cidr_blocks {
        cidr_block = "0.0.0.0/0"
    }
  }
}

resource "google_container_node_pool" "cluster_pool" {
  depends_on = [time_sleep.wait_for_services]
  name       = "cluster-pool"
  location   = "europe-west1-b"
  cluster    = google_container_cluster.cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    service_account = google_service_account.cluster_sa.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    tags = ["cluster-vms"]
  }
  autoscaling {
      min_node_count = "1"
      max_node_count = "4"
  }
}