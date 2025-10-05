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
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# =============================================================================
# ENABLE REQUIRED APIS
# =============================================================================

resource "google_project_service" "apigateway_api" {
  service = "apigateway.googleapis.com"
}

resource "google_project_service" "servicemanagement_api" {
  service = "servicemanagement.googleapis.com"
}

resource "google_project_service" "servicecontrol_api" {
  service = "servicecontrol.googleapis.com"
}

resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
}

# =============================================================================
# SERVICE ACCOUNT FOR API GATEWAY
# =============================================================================
# Using existing service account: terraform-gcp@allygo.iam.gserviceaccount.com

data "google_service_account" "terraform_gcp" {
  account_id = "terraform-gcp"
}

# Grant permissions to invoke Cloud Run services
resource "google_project_iam_member" "api_gateway_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${data.google_service_account.terraform_gcp.email}"
}

# Grant permissions for Service Management (required for API Gateway)
resource "google_project_iam_member" "api_gateway_service_agent" {
  project = var.project_id
  role    = "roles/servicemanagement.serviceController"
  member  = "serviceAccount:${data.google_service_account.terraform_gcp.email}"
}

# =============================================================================
# STATIC IP FOR API GATEWAY (OPTIONAL)
# =============================================================================

resource "google_compute_global_address" "api_gateway_ip" {
  name = "${var.api_gateway_name}-ip"
}

# =============================================================================
# API GATEWAY API
# =============================================================================

resource "google_api_gateway_api" "api" {
  provider = google-beta
  api_id   = var.api_gateway_name

  depends_on = [google_project_service.apigateway_api]
}

# =============================================================================
# API GATEWAY API CONFIG
# =============================================================================

resource "google_api_gateway_api_config" "api_config" {
  provider      = google-beta
  api           = google_api_gateway_api.api.api_id
  api_config_id = "${var.api_gateway_name}-config"

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = base64encode(templatefile("${path.module}/openapi.yaml", {
        project_id               = var.project_id
        region                   = var.region
        services_management_url  = var.services_management_service_url
        payments_url             = var.payments_service_url
        users_url                = var.users_service_url
        orders_url               = var.orders_service_url
      }))
    }
  }

  gateway_config {
    backend_config {
      google_service_account = data.google_service_account.terraform_gcp.email
    }
  }

  # Display name for better identification
  display_name = "${var.api_gateway_name} - Cloud Run Backend"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_project_service.apigateway_api,
    google_project_service.servicemanagement_api,
    google_project_service.servicecontrol_api
  ]
}

# =============================================================================
# API GATEWAY GATEWAY
# =============================================================================

resource "google_api_gateway_gateway" "gateway" {
  provider   = google-beta
  api_config = google_api_gateway_api_config.api_config.id
  gateway_id = var.api_gateway_name
  region     = var.region

  depends_on = [google_api_gateway_api_config.api_config]
}
