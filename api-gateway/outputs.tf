# =============================================================================
# OUTPUTS
# =============================================================================

output "api_gateway_url" {
  description = "URL of the deployed API Gateway"
  value       = google_api_gateway_gateway.gateway.default_hostname
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = google_api_gateway_gateway.gateway.gateway_id
}

output "api_id" {
  description = "API ID"
  value       = google_api_gateway_api.api.api_id
}

output "service_account_email" {
  description = "Email of the API Gateway service account"
  value       = data.google_service_account.terraform_gcp.email
}

output "static_ip" {
  description = "Static IP address reserved for API Gateway (for custom domain)"
  value       = google_compute_global_address.api_gateway_ip.address
}

output "dns_configuration" {
  description = "DNS configuration for custom domain"
  value       = "Create A record: api.allygo.com → ${google_compute_global_address.api_gateway_ip.address}"
}

output "example_curl_command" {
  description = "Example curl command to test the API Gateway"
  value       = "curl https://${google_api_gateway_gateway.gateway.default_hostname}/api/payments/health"
}
