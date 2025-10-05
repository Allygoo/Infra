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

# =============================================================================
# LOAD BALANCER OUTPUTS
# =============================================================================

output "load_balancer_ip" {
  description = "IP address of the Load Balancer (use this for DNS A record)"
  value       = google_compute_global_address.api_gateway_ip.address
}

output "load_balancer_url" {
  description = "URL to access API via Load Balancer (if custom domain configured)"
  value       = var.custom_domain != "" ? "https://${var.custom_domain}" : "Use API Gateway URL directly: https://${google_api_gateway_gateway.gateway.default_hostname}"
}

output "backend_service_name" {
  description = "Name of the backend service"
  value       = google_compute_backend_service.api_gateway_backend.name
}

output "serverless_neg_name" {
  description = "Name of the Serverless Network Endpoint Group"
  value       = google_compute_region_network_endpoint_group.api_gateway_neg.name
}

output "ssl_certificate_status" {
  description = "Status of the SSL certificate (if custom domain configured)"
  value       = var.custom_domain != "" ? "Certificate provisioning may take up to 20 minutes. Check: gcloud compute ssl-certificates describe ${var.api_gateway_name}-ssl-cert --global" : "No custom domain configured - SSL certificate not created"
}

output "dns_setup_instructions" {
  description = "Instructions to configure DNS for custom domain"
  value = var.custom_domain != "" ? join("\n", [
    "To complete the setup:",
    "",
    "1. Create an A record in your DNS provider:",
    "   - Name: ${var.custom_domain}",
    "   - Type: A",
    "   - Value: ${google_compute_global_address.api_gateway_ip.address}",
    "   - TTL: 300 (or default)",
    "",
    "2. Wait for DNS propagation (5-60 minutes)",
    "",
    "3. Wait for SSL certificate provisioning (up to 20 minutes after DNS propagation)",
    "   Check status with: gcloud compute ssl-certificates describe ${var.api_gateway_name}-ssl-cert --global",
    "",
    "4. Test your API:",
    "   curl https://${var.custom_domain}/api/payments/health",
    "",
    "Note: The certificate will only provision after the DNS A record is correctly configured."
  ]) : "No custom domain configured. To use a custom domain, set the 'custom_domain' variable."
}

output "load_balancer_components" {
  description = "Summary of Load Balancer components created"
  value = {
    serverless_neg    = google_compute_region_network_endpoint_group.api_gateway_neg.name
    backend_service   = google_compute_backend_service.api_gateway_backend.name
    url_map           = google_compute_url_map.api_gateway_url_map.name
    ssl_certificate   = var.custom_domain != "" ? google_compute_managed_ssl_certificate.api_gateway_cert[0].name : "Not created (no custom domain)"
    https_proxy       = var.custom_domain != "" ? google_compute_target_https_proxy.api_gateway_https_proxy[0].name : "Not created (no custom domain)"
    http_proxy        = var.enable_http_proxy ? google_compute_target_http_proxy.api_gateway_http_proxy[0].name : "Not created"
    forwarding_rule   = var.custom_domain != "" ? google_compute_global_forwarding_rule.api_gateway_https_forwarding_rule[0].name : "Not created (no custom domain)"
    static_ip         = google_compute_global_address.api_gateway_ip.address
  }
}
