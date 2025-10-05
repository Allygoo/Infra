# =============================================================================
# INPUT VARIABLES
# =============================================================================

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region for API Gateway"
  type        = string
  default     = "us-east1"
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "allygo-api-gateway"
}

variable "services_management_service_url" {
  description = "Backend URL for Services Management microservice (Cloud Run)"
  type        = string
  # Example: "https://services-management-ms-xxxxx-ue.a.run.app" for Cloud Run
}

variable "payments_service_url" {
  description = "Backend URL for Payments microservice (Cloud Run)"
  type        = string
  # Example: "https://payments-ms-xxxxx-ue.a.run.app" for Cloud Run
}

variable "users_service_url" {
  description = "Backend URL for Users microservice (Cloud Run)"
  type        = string
  default     = ""
}

variable "orders_service_url" {
  description = "Backend URL for Orders microservice (Cloud Run)"
  type        = string
  default     = ""
}

variable "enable_cors" {
  description = "Enable CORS for API Gateway"
  type        = bool
  default     = true
}

variable "allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

# =============================================================================
# LOAD BALANCER VARIABLES
# =============================================================================

variable "custom_domain" {
  description = "Custom domain for API Gateway (e.g., api.allygo.com). Leave empty to use default API Gateway URL"
  type        = string
  default     = ""
}

variable "enable_cdn" {
  description = "Enable Cloud CDN for the API Gateway backend"
  type        = bool
  default     = false
}

variable "enable_http_proxy" {
  description = "Enable HTTP (port 80) proxy for testing. Traffic will be redirected to HTTPS in production"
  type        = bool
  default     = false
}

variable "enable_cloud_armor" {
  description = "Enable Cloud Armor security policy for DDoS and WAF protection"
  type        = bool
  default     = false
}
