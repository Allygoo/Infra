# =============================================================================
# INPUT VARIABLES
# =============================================================================

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region for resources"
  type        = string
  default     = "us-central1"
}

variable "gke_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "allygo-cluster"
}

variable "artifact_repo" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "microservices-repo-allygo"
}

variable "api_gateway_domain" {
  description = "Domain name for the API Gateway (Ingress)"
  type        = string
  default     = "api.allygo.com"
}
