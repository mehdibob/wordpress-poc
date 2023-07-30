resource "google_compute_global_address" "wordpress_db" {
  name          = "wordpress-db"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.test_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.test_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.wordpress_db.name]
}

resource "google_sql_database_instance" "wordpress_db" {
  name   = "wordpress-db"
  database_version = "MYSQL_8_0"
  region = "europe-west1"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-custom-2-4096"
    availability_type = "ZONAL"
    disk_size = "100"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.test_vpc.id
    }
  }
}

resource "google_sql_user" "wordpress_db_user" {
  name     = "admin"
  instance = google_sql_database_instance.wordpress_db.name
  password = "bFZY0Af381e7"
}

resource "google_sql_database" "wordpress" {
  name     = "wordpress"
  instance = google_sql_database_instance.wordpress_db.name
}

# Outputs :
output "wordpress_db_ip_address" {
  value = google_sql_database_instance.wordpress_db.private_ip_address
}