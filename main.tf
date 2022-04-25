provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "project" {
  project = var.project_id
  service = "container.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.name}-gke"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = var.project_id
    }

    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.name}-gke"]
    metadata     = {
      disable-legacy-endpoints = "true"
    }

    service_account = google_service_account.default.email
  }
}

# # Kubernetes provider
# # The Terraform Kubernetes Provider configuration below is used as a learning reference only.
# # It references the variables and resources provisioned in this file.
# # We recommend you put this in another file -- so you can have a more modular configuration.
# # https://learn.hashicorp.com/terraform/kubernetes/provision-gke-cluster#optional-configure-terraform-kubernetes-provider
# # To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider.
provider "kubernetes" {
   load_config_file = "false"

   host     = google_container_cluster.primary.endpoint
   username = var.gke_username
   password = var.gke_password

   client_certificate     = google_container_cluster.primary.master_auth.0.client_certificate
   client_key             = google_container_cluster.primary.master_auth.0.client_key
   cluster_ca_certificate = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
}

#https://github.com/bitnami/charts/tree/master/bitnami/jenkins/
/*resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "jenkins"
  version    = "10.0.6"
  timeout    = 900
}
*/














/*
provider "google-beta" {
  project = var.project
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = var.network_name
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = true
}

resource "google_compute_router" "default" {
  name    = "code-editor-router"
  network = google_compute_network.default.self_link
  region  = var.region
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "1.4.0"
  router     = google_compute_router.default.name
  project_id = var.project
  region     = var.region
  name       = "code-editor-nat"
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "code-editor-cert"

  managed {
    domains = [var.domain_name]
  }
}

module "gce-lb-http" {
  source               = "GoogleCloudPlatform/lb-http/google"
  version              = "~> 5.1"
  name                 = "code-editor-https-load-balancer"
  project              = var.project
  target_tags          = [var.network_name]
  firewall_networks    = [google_compute_network.default.name]
  ssl                  = true
  ssl_certificates     = [google_compute_managed_ssl_certificate.default.self_link]
  use_ssl_certificates = true
  https_redirect       = true

  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 300
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null

      health_check = {
        check_interval_sec  = 300
        timeout_sec         = 300
        healthy_threshold   = 1
        unhealthy_threshold = 5
        request_path        = "/healthz"
        port                = 80
        host                = null
        logging             = true
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group                        = module.mig.instance_group
          balancing_mode               = "UTILIZATION"
          capacity_scaler              = 1.0
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        }
      ]
      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
    }
  }
}

provider "namedotcom" {
  token = var.name_com_token
  username = var.name_com_username
}

resource "namedotcom_record" "foo" {
  domain_name = var.domain_name
  record_type = "A"
  answer = module.gce-lb-http.external_ip
}
*/
#manual stuff - enable iap for external users which is not possible via terraform