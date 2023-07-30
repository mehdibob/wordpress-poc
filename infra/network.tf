# Network resources
resource "google_compute_network" "test_vpc" {
  name                    = "test-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "vm_subnet" {
  name          = "vm-subnet"
  ip_cidr_range = "10.10.10.0/24"
  region        = "europe-west1"
  private_ip_google_access   = true
  network       = google_compute_network.test_vpc.id
  depends_on    = [google_compute_network.test_vpc]
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.5.0.0/16"
  }
  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "10.4.0.0/16"
  }

}

resource "google_compute_router" "cluster_router" {
  name    = "cluster-router"
  region  = google_compute_subnetwork.vm_subnet.region
  network = google_compute_network.test_vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_address" "cluster_out" {
  name   = "cluster-out"
  region = google_compute_subnetwork.vm_subnet.region
}

resource "google_compute_router_nat" "cluster_nat" {
  name                               = "cluster-nat"
  router                             = google_compute_router.cluster_router.name
  region                             = google_compute_router.cluster_router.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.cluster_out.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.vm_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

}



output "cluster-outgoing-address" {
  value = google_compute_address.cluster_out.address
}