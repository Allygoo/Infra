# =============================================================================
# TERRAFORM CONFIGURATION
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Kubernetes provider - connects to GKE cluster
provider "kubernetes" {
  host                   = "https://${google_container_cluster.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
}

# Data source for GCP access token
data "google_client_config" "default" {}

# =============================================================================
# ENABLE REQUIRED APIS
# =============================================================================

resource "google_project_service" "container_api" {
  service = "container.googleapis.com"
}

resource "google_project_service" "artifact_api" {
  service = "artifactregistry.googleapis.com"
}

# =============================================================================
# ARTIFACT REGISTRY
# =============================================================================

resource "google_artifact_registry_repository" "repo" {
  repository_id = var.artifact_repo
  format        = "DOCKER"
  location      = var.region
  description   = "Docker images for Allygo microservices"

  depends_on = [google_project_service.artifact_api]
}

# =============================================================================
# GKE CLUSTER
# =============================================================================

resource "google_container_cluster" "gke" {
  name               = var.gke_name
  location           = "${var.region}-a" # Zonal cluster for cost optimization
  initial_node_count = 1

  # Remove default node pool to manage separately
  remove_default_node_pool = true

  # Network configuration
  network = "default"
  ip_allocation_policy {} # Enable VPC-native networking

  # Cluster add-ons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    # Note: kubernetes_dashboard addon was deprecated and removed
    # Use kubectl proxy or Google Cloud Console for cluster management
  }

  # Lifecycle management
  lifecycle {
    ignore_changes = [node_pool]
  }

  depends_on = [google_project_service.container_api]
}

# =============================================================================
# GKE NODE POOL
# =============================================================================

resource "google_container_node_pool" "primary_nodes" {
  name     = "primary-pool"
  cluster  = google_container_cluster.gke.name
  location = google_container_cluster.gke.location

  # Node configuration
  node_config {
    machine_type = "e2-medium" # 2 vCPUs, 4 GB RAM

    # OAuth scopes for node access to GCP services
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Node labels
    labels = {
      role = "app"
    }

    # Network tags
    tags = ["gke-node", "allow-health-check"]
  }

  # Auto-scaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Lifecycle management - prevent unnecessary updates
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      node_config[0].labels,
      node_config[0].taint,
      initial_node_count
    ]
  }
}

# =============================================================================
# CI/CD SERVICE ACCOUNT
# =============================================================================

resource "google_service_account" "github_actions" {
  account_id   = "github-actions"
  display_name = "GitHub Actions CI/CD Service Account"
  description  = "Service account for GitHub Actions to deploy to GKE and push to Artifact Registry"
}

# Grant permissions to push Docker images
resource "google_project_iam_member" "artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Grant permissions to deploy to GKE
resource "google_project_iam_member" "gke_deployer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# =============================================================================
# KUBERNETES INGRESS (OPTIONAL)
# =============================================================================

# Static global IP for Ingress
resource "google_compute_global_address" "ingress_ip" {
  name = "${var.gke_name}-ingress-ip"
}

# Ingress resource (Kubernetes Ingress Controller)
resource "kubernetes_ingress_v1" "api_gateway" {
  metadata {
    name = "allygo-gateway"
    annotations = {
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.ingress_ip.name
      # Optional: Enable HTTPS with Google-managed certificate
      # "networking.gke.io/managed-certificates" = "allygo-cert"
      # Optional: Redirect HTTP to HTTPS
      # "kubernetes.io/ingress.allow-http" = "false"
    }
  }

  spec {
    rule {
      host = var.api_gateway_domain

      http {
        # Payment microservice routes
        path {
          path      = "/api/payments"
          path_type = "Prefix"

          backend {
            service {
              name = "payments-ms"
              port {
                number = 80
              }
            }
          }
        }

        # Add more microservices here:
        # Uncomment and modify as needed
        # path {
        #   path      = "/api/orders"
        #   path_type = "Prefix"
        #   backend {
        #     service {
        #       name = "orders-ms"
        #       port {
        #         number = 80
        #       }
        #     }
        #   }
        # }
        #
        # path {
        #   path      = "/api/users"
        #   path_type = "Prefix"
        #   backend {
        #     service {
        #       name = "users-ms"
        #       port {
        #         number = 80
        #       }
        #     }
        #   }
        # }
      }
    }
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

# Optional: Managed SSL Certificate
# Uncomment to enable HTTPS
# resource "kubernetes_manifest" "managed_cert" {
#   manifest = {
#     apiVersion = "networking.gke.io/v1"
#     kind       = "ManagedCertificate"
#     metadata = {
#       name = "allygo-cert"
#     }
#     spec = {
#       domains = [var.api_gateway_domain]
#     }
#   }
#   depends_on = [google_container_node_pool.primary_nodes]
# }
