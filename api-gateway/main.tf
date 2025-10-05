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

# =============================================================================
# LOAD BALANCER CONFIGURATION (SERVERLESS NEG)
# =============================================================================

# Serverless Network Endpoint Group (NEG) for API Gateway
resource "google_compute_region_network_endpoint_group" "api_gateway_neg" {
  provider              = google-beta
  name                  = "${var.api_gateway_name}-serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  serverless_deployment {
    platform = "apigateway.googleapis.com"
    resource = google_api_gateway_gateway.gateway.gateway_id
  }

  depends_on = [google_api_gateway_gateway.gateway]
}

# Backend Service - defines how the load balancer distributes traffic
resource "google_compute_backend_service" "api_gateway_backend" {
  name        = "${var.api_gateway_name}-backend-service"
  protocol    = "HTTPS"
  timeout_sec = 30

  # Enable Cloud CDN if desired (optional)
  enable_cdn = var.enable_cdn

  backend {
    group = google_compute_region_network_endpoint_group.api_gateway_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL Map - routes incoming requests to the backend service
resource "google_compute_url_map" "api_gateway_url_map" {
  name            = "${var.api_gateway_name}-url-map"
  default_service = google_compute_backend_service.api_gateway_backend.id

  # Optional: Add host rules and path matchers for multiple backends
  # host_rule {
  #   hosts        = [var.custom_domain]
  #   path_matcher = "api-gateway-path-matcher"
  # }
  #
  # path_matcher {
  #   name            = "api-gateway-path-matcher"
  #   default_service = google_compute_backend_service.api_gateway_backend.id
  # }
}

# SSL Certificate - managed by Google (requires domain ownership)
resource "google_compute_managed_ssl_certificate" "api_gateway_cert" {
  count = var.custom_domain != "" ? 1 : 0
  name  = "${var.api_gateway_name}-ssl-cert"

  managed {
    domains = [var.custom_domain]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTPS Target Proxy - routes requests to the URL map
resource "google_compute_target_https_proxy" "api_gateway_https_proxy" {
  count   = var.custom_domain != "" ? 1 : 0
  name    = "${var.api_gateway_name}-https-proxy"
  url_map = google_compute_url_map.api_gateway_url_map.id

  ssl_certificates = [google_compute_managed_ssl_certificate.api_gateway_cert[0].id]
}

# HTTP Target Proxy - for testing without SSL (optional)
resource "google_compute_target_http_proxy" "api_gateway_http_proxy" {
  count   = var.enable_http_proxy ? 1 : 0
  name    = "${var.api_gateway_name}-http-proxy"
  url_map = google_compute_url_map.api_gateway_url_map.id
}

# Global Forwarding Rule - HTTPS (443)
resource "google_compute_global_forwarding_rule" "api_gateway_https_forwarding_rule" {
  count                 = var.custom_domain != "" ? 1 : 0
  name                  = "${var.api_gateway_name}-https-forwarding-rule"
  target                = google_compute_target_https_proxy.api_gateway_https_proxy[0].id
  port_range            = "443"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.api_gateway_ip.address
}

# Global Forwarding Rule - HTTP (80) - redirects to HTTPS
resource "google_compute_global_forwarding_rule" "api_gateway_http_forwarding_rule" {
  count                 = var.enable_http_proxy ? 1 : 0
  name                  = "${var.api_gateway_name}-http-forwarding-rule"
  target                = google_compute_target_http_proxy.api_gateway_http_proxy[0].id
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.api_gateway_ip.address
}

# =============================================================================
# CLOUD ARMOR SECURITY POLICY (OPTIONAL)
# =============================================================================

# Uncomment to enable Cloud Armor protection
# resource "google_compute_security_policy" "api_gateway_security_policy" {
#   name = "${var.api_gateway_name}-security-policy"
#
#   # Block common web attacks
#   rule {
#     action   = "deny(403)"
#     priority = "1000"
#     match {
#       expr {
#         expression = "evaluatePreconfiguredExpr('sqli-stable')"
#       }
#     }
#     description = "Block SQL injection attacks"
#   }
#
#   rule {
#     action   = "deny(403)"
#     priority = "1001"
#     match {
#       expr {
#         expression = "evaluatePreconfiguredExpr('xss-stable')"
#       }
#     }
#     description = "Block XSS attacks"
#   }
#
#   # Allow all other traffic
#   rule {
#     action   = "allow"
#     priority = "2147483647"
#     match {
#       versioned_expr = "SRC_IPS_V1"
#       config {
#         src_ip_ranges = ["*"]
#       }
#     }
#     description = "Default allow rule"
#   }
# }
#
# # Attach security policy to backend service
# resource "google_compute_backend_service_iam_member" "security_policy_attachment" {
#   backend_service = google_compute_backend_service.api_gateway_backend.name
#   security_policy = google_compute_security_policy.api_gateway_security_policy.id
# }
