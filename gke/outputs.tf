# =============================================================================
# OUTPUTS
# =============================================================================

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.gke.name
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.gke.location
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.gke.endpoint
  sensitive   = true
}

output "artifact_registry_url" {
  description = "Full URL of the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}

output "ci_service_account_email" {
  description = "Email of the CI/CD service account"
  value       = google_service_account.github_actions.email
}

output "ingress_ip_address" {
  description = "Static IP address for the Ingress (Kubernetes Ingress Controller)"
  value       = google_compute_global_address.ingress_ip.address
}

output "api_gateway_domain" {
  description = "Domain configured for the Kubernetes Ingress"
  value       = var.api_gateway_domain
}

output "dns_configuration" {
  description = "DNS A record configuration for your domain registrar"
  value       = "${var.api_gateway_domain} → A record → ${google_compute_global_address.ingress_ip.address}"
}

output "kubectl_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.gke.name} --zone=${google_container_cluster.gke.location} --project=${var.project_id}"
}
