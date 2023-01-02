resource "google_compute_network" "this" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name                     = var.network_name
  ip_cidr_range            = "10.0.0.0/20"
  network                  = google_compute_network.this.self_link
  region                   = var.region
  private_ip_google_access = true
}

resource "google_compute_router" "this" {
  name    = "router"
  network = google_compute_network.this.self_link
  region  = var.region
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "2.2.1"
  router     = google_compute_router.this.name
  project_id = var.project
  region     = var.region
  name       = "cloud-nat"
}

module "mig_template" {
  source               = "terraform-google-modules/vm/google//modules/instance_template"
  version              = "7.9.0"
  network              = google_compute_network.this.self_link
  subnetwork           = google_compute_subnetwork.this.self_link
  machine_type         = "e2-micro"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"
  disk_size_gb         = "20"
  name_prefix          = "http-ubuntu-vm"
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  tags           = ["allow-lb"]
  startup_script = file("startup-script.sh")
}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "7.9.0"
  instance_template = module.mig_template.self_link
  region            = var.region
  hostname          = "http-ubuntu-vm"
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.this.self_link
  subnetwork = google_compute_subnetwork.this.self_link
}
