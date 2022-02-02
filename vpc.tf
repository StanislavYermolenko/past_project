
resource "google_compute_network" "vpc_network" {
  project                 = var.PROJECT_ID
  name                    = "vpc-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "vpc-subnetwork"
  ip_cidr_range = "192.168.10.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  project       = var.PROJECT_ID
}

resource "google_compute_address" "static" {
  name          = "ipv4-address"
  region        = var.region
  project       = var.PROJECT_ID
}