# Module Outputs
output "cluster_id" {
  description = "ID of the created Kubernetes cluster"
  value       = scaleway_k8s_cluster.k8s.id
}

output "cluster_name" {
  description = "Name of the created Kubernetes cluster"
  value       = scaleway_k8s_cluster.k8s.name
}

output "kubeconfig" {
  description = "Path to the generated kubeconfig file"
  value       = "${path.module}/kubeconfig.yaml"
}

output "client_type_a_pool_id" {
  description = "ID of the Client Type A worker pool"
  value       = scaleway_k8s_pool.client_type_a_pool.id
}

output "client_type_b_pool_id" {
  description = "ID of the Client Type B worker pool"
  value       = scaleway_k8s_pool.client_type_b_pool.id
}
