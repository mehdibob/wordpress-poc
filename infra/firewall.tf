resource "google_compute_firewall" "healthcheckers" {
  depends_on = [time_sleep.wait_for_services]
  allow {
    ports    = ["10256", "80", "8080"]
    protocol = "tcp"
  }

  direction      = "INGRESS"
  disabled       = "false"
  name           = "healthcheckers"
  network        = google_compute_network.test_vpc.id
  priority       = "1000"
  source_ranges  = ["35.191.0.0/16", "209.85.152.0/22", "130.211.0.0/22", "209.85.204.0/22"]
  target_tags = ["cluster-vms"]
}